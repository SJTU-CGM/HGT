#!/bin/bash

###############################
### pipeline to identify HGTs #
### example: bosTau7          #
###############################


#####################################################################################
### step 1: split the genome and screen short segments based on k-mer frequencies ###
#####################################################################################
# fragment length: 1kbp; overlap 200bp
# reference genome: fa/bosTau7.fa (assembly id: GCF_000003205.5)
perl src/segment.pl fa/bosTau7.fa 1000 800 segment/bosTau7-seg1k-step0.8k.fa
perl src/kmerGenome.pl fa/bosTau7.fa 4 > segment/bosTau7-4mer.txt # k=4
perl src/kmer.pl segment/bosTau7-seg1k-step0.8k.fa 4 > segment/bosTau7-seg1k-step0.8k-4mer.txt
# compare k-mer composition of fragments with that of reference genome
perl src/compareKmer.pl segment/bosTau7-4mer.txt segment/bosTau7-seg1k-step0.8k-4mer.txt segment/bosTau7-seg1k-step0.8k-4mer-distance.txt

num=$(grep -v region segment/bosTau7-seg1k-step0.8k-4mer-distance.txt |wc -l)
top=`expr $num / 100` # only top 1% kept
grep -v region segment/bosTau7-seg1k-step0.8k-4mer-distance.txt |sort -rnk 2 |head -$top |awk '{print $1}' > segment/bosTau7-seg1k-step0.8k-4mer-distance-pass.info

awk -F '-' '{print $1"\t"$2"\t"$3}' segment/bosTau7-seg1k-step0.8k-4mer-distance-pass.info |sort -k1,1 -k2n,2 > segment/bosTau7-seg1k-step0.8k-4mer-distance-pass.bed

perl src/getHGTseq.pl fa/bosTau7.fa segment/bosTau7-seg1k-step0.8k-4mer-distance-pass.bed segment/bosTau7-seg1k-step0.8k-4mer-distance-pass.fa
# compare with simple_repeat track, and remove fragments containing simple_repeat
perl src/biodiff.pl data/simple_repeat-merge.bed segment/bosTau7-seg1k-step0.8k-4mer-distance-pass.bed |awk '{print $1"-"$2"-"$3}' |sort |uniq >segment/overlap_simple_repeat.info
# screened short fragment: fa/bosTau7-screen.fa
perl filterFA_notmatch.pl segment/bosTau7-seg1k-step0.8k-4mer-distance-pass.fa segment/overlap_simple_repeat.info fa/bosTau7-screen.fa



###################################
### step 2: run LASTZ alignment ###
###################################
for id in `cat data/825genome.id`
do
    lastz fa/bosTau7-screen.fa[multiple] genomes/$id.fna --format=axt+ --output=axt/$id.axt --ambiguous=iupac #LASTZ raw output: axt+ format
    perl src/axt2cov.pl cov/$id.cov axt/$id.axt
    perl src/cov2bed.pl cov/$id.cov |sort -k1,1 -k2n,2 |uniq >cov/$id.bed #convert to bed format
    
    arr=(50 70) # two threshold of alignment identity: 50% and 70%
    for threshold in ${arr[@]}
    do
	# filter the aligned regions using identity threshold
	awk '{if($9*100>='$threshold') print $1"\t"$2"\t"$3}' cov/$id.cov |sort -k1,1 -k2n,2 > iden$threshold/$id.bed
	num=$(cat iden$threshold/$id.bed |wc -l)
	if [ $num != 0 ]
	then
	    perl src/mergeBed.pl iden$threshold/$id.bed tmp.txt
	    mv tmp.txt iden$threshold/$id.bed
	fi
    done
done



#####################################################
### step 3: identify HGTs according to LASTZ result #
#####################################################
for id in `cat data/close.id` # 113 close species (CRG group) --> directory /close
do
    # threshold: identity>50%
    awk -F '-|\t' '{print $1"\t"$2+$4-1"\t"$2+$5-1}' iden50/$id.bed |sort -k1,1 -k2n,2 |uniq |perl src/mergeBed.pl - close/$id.bed
done

for id in `cat $i/remote.id` # 710 remote species (DRG group) --> directory /remote
do
    # threshold: identity>70% and aligned length>200bp
    awk -F '-|\t' '{print $1"\t"$2+$4-1"\t"$2+$5-1}' iden70/$id.bed |sort -k1,1 -k2n,2 |uniq |perl src/mergeBed.pl - tmp.txt
    cat tmp.txt |awk '{if($3-$2+1 >= 200) print $0}' > remote/$id.bed
done
cat remote/*bed |sort -k1,1 -k2n,2 |uniq > remote/merge.txt # all the regions matched to remote species

# count CRG scale for each region that is matched to remote species
# for species in CRG group, length coverage threshold is set 0.6 (with identity > 50%, it covers more than 60% of this region)
perl src/screenHGT2.pl remote/merge.txt - 0.6 close/*bed |sort -k1,1 -k2n,2 |uniq > all.out
perl src/getHGTseqInfo.pl fa/bosTau7.fa all.out all.fa #fasta format, with corresponding CRG scale

# remove sequences with "NNN" (gap region)
perl src/removeNNN.pl all.fa nonN.fa
grep ">" nonN.fa |tr -d ">" |awk -F '-|\t' '{print $1"\t"$2"\t"$3"\t"$4}' > nonN.out
awk '{print $1"\t"$2"\t"$3}' nonN.out |sort -k1,1 -k2n,2 |uniq > nonN.bed
awk '{print $1"-"$2"-"$3}' nonN.bed > nonN.id

# remove sequences with Simple_repeat, Low_complexity or GC percentage<0.3 or GC percentage>0.6
perl src/kmer.pl nonN.fa 1 > nonN-gc.txt
awk '{if($4+$5<0.3 || $4+$5>0.6) print $1}' nonN-gc.txt > delete.id
perl src/biodiff.pl data/rmsk.bed nonN.bed |egrep "Simple|Low" |awk '{print $1"-"$2"-"$3}' |sort |uniq >> delete.id
cat delete.id |sort |uniq > tmp.txt
mv tmp.txt delete.id
perl src/notin.pl delete.id nonN.id > remain.id
perl src/filterFA_match.pl nonN.fa remain.id remain.fa

# gradient pipeline, to merge overlapped regions with different CRG scale
grep ">" remain.fa |tr -d ">" |awk -F '\t|-' '{print $1"\t"$2"\t"$3"\t"$4}' | sort -k1,1 -k2n,2 |uniq > remain.out
for ((j=0; j<=30; j ++)) # different thresholds of CRG scale: 1~30
do
    awk '{if($4=='$j') print $1"\t"$2"\t"$3}' remain.out |sort -k1,1 -k2n,2 |uniq > tmp.bed
    num=$(cat tmp.bed |wc -l)
    if [ $num != 0 ]
    then
	perl src/mergeBed.pl tmp.bed gradient/individual/cov$j.bed
    else
	cp tmp.bed gradient/individual/cov$j.bed
    fi
done

awk '{print $0"\t"0}' gradient/individual/cov0.bed > gradient/total/cov0.bed

for ((j=1; j<=30; j ++)) # merge two regions that overlapped
do
    k=`expr $j - 1`
    perl src/biodiff.pl gradient/total/cov$k.bed gradient/individual/cov$j.bed |awk '{print $1"\t"$2"\t"$3}' |sort -k1,1 -k2n,2 > tmp.bed
    perl src/notin.pl tmp.bed gradient/individual/cov$j.bed |awk '{print $0"\t'$j'"}'> add.bed
    cat gradient/total/cov$k.bed add.bed |sort -k1,1 -k2n,2 > gradient/total/cov$j.bed

    perl src/getHGTseqInfo.pl fa/bosTau7.fa gradient/total/cov$j.bed gradient/total/cov$j.fa
    RepeatMasker gradient/total/cov$j.fa # de novo RepearMasker to label Simple_repeat and Low_complexity
    awk '{print $1"-"$2"-"$3}' gradient/total/cov$j.bed > gradient/total/cov$j.id
    egrep "Simple|Low" gradient/total/cov$j.fa.out |awk '{print $5}' |sort |uniq > gradient/total/cov$j.delete.id
    perl src/notin.pl gradient/total/cov$j.delete.id gradient/total/cov$j.id > gradient/total/cov$j.filter.id
    perl src/filterFA_match.pl gradient/total/cov$j.fa gradient/total/cov$j.filter.id gradient/total/cov$j.filter.fa
done

# for each sequence, count the number of organisms in different groups
# groups: fungi, plant, protozoa, invertebrate, vertebrate_other and vertebrate_mammalian
cat gradient/total/*filter.id |sort |uniq > build.input.txt
for id in `cat build.input.txt`
do
    chr=$(echo $id | awk -F '-' '{print $1}')
    start=$(echo $id | awk -F '-' '{print $2}')
    end=$(echo $id | awk -F '-' '{print $3}')

    mkdir tree/$id
    # set length coverage threshold: 60%
    grep "$chr\s" cov/*bed |awk '{if(!($2>='$end' || $3<='$start') && $9 >= 0.5) print $0}' | awk -F 'cov/|.bed|\t' '{print $2"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11}' |perl src/screenHit.pl - $start $end 0.6 data/close.id 0.7 tree/$id/cov.txt
    perl src/getMatch.pl tree/$id/cov.txt tree/$id/cov-hit.txt # best match for each species
done

echo -e "id\tfungi\tplant\tprotozoa\tinvertebrate\tvertebrate_other\tvertebrate_mammalian\tall_species" > tree.info
for id in `cat build.input.txt`
do
    species=$(perl src/treeSpecies.pl tree/$id/cov-hit.txt data/type.txt)
    echo -e "$id\t$species" >> tree.info
done
# if this sequence doesn't appear in any remote species, it's removed
awk '{if($8-$7==0) print $1}' tree.info > tree.delete.id

for ((j=0; j<=30; j ++))
do
    perl src/notin.pl tree.delete.id gradient/total/cov$j.filter.id > gradient/total/cov$j.filter2.id
    perl src/filterFA_match.pl gradient/total/cov$j.filter.fa gradient/total/cov$j.filter2.id gradient/total/cov$j.filter2.fa
    # remove redundancy using cd-hit-est, set identity 80%
    cd-hit-est -i gradient/total/cov$j.filter2.fa -c 0.8 -o gradient/total/cov$j.filter2.cdhit0.8.fa    
done

# threshold of CRG scale: 17
# Generate filtered HGTs (non-redundant): filtered.fa
cp gradient/total/cov17.filter2.cdhit0.8.fa filtered.fa
grep ">" filtered.fa |awk '{print $1}' |tr -d ">" > filtered.id
awk -F '-' '{print $1"\t"$2"\t"$3}' filtered.id |sort -k1,1 -k2n,2 > filtered.bed

# Removing HGTs with ERVs
perl src/biodiff.pl ERV/ERV.bed filtered.bed > ERV/HGT2ERV.txt # coordinate comparison
awk '{print $1"-"$2"-"$3}' ERV/HGT2ERV.txt |sort |uniq > ERV/remove.txt
perl src/getHGTseq.pl fa/bosTau7.fa ERV/ERV.bed ERV/ERV.fa
makeblastdb -in ERV/ERV.fa -dbtype nucl
blastn -task blastn -query filtered.fa -db ERV/ERV.fa -out ERV/blast.txt -evalue 1e-5 -outfmt 7 -num_threads 4 #blastn alignment
grep -v "#" ERV/blast.txt |awk '{if($3>=90 && $4>=100) print $1}' |sort |uniq >> ERV/remove.txt

##################################
### Final HGT result: noERV.fa ###
##################################
perl src/notin.pl ERV/remove.txt filtered.id > noERV.id
awk -F '-' '{print $1"\t"$2"\t"$3}' noERV.id |sort -k1,1 -k2n,2 > noERV.bed
perl src/filterFA_match.pl filtered.fa noERV.id noERV.fa



##################################################################
### step 4: Build phylogenetic tree for each non-redundant HGT ###
##################################################################
for hgt in `cat noERV.id`
do
    perl src/cov-overlap.pl tree/$hgt/cov-hit.txt $hgt tree-filtered/$hgt.hit.spesies.txt
    mkdir tree-filtered/$hgt tree-filtered/$hgt/hit
    echo ">bosTau7" > tree-filtered/$hgt/bosTau7.fa
    grep -A 1 $hgt noERV.fa |tail -n 1 >> tree-filtered/$hgt/bosTau7.fa
    for target in `cat tree-filtered/$hgt.hit.spesies.txt |grep -v hit_species`
    do
	species=$(echo $target |awk '{print $1}')
	bed=$(echo $target |awk '{print $2"\t"$3"\t"$4"\t"$5}')
	echo $bed > tree-filtered/$hgt/hit/$species.bed
	### Homologous sequence in these species
	perl src/getSeq.pl genomes/$species.fna tree-filtered/$hgt/hit/$species.bed tree-filtered/$hgt/hit/$species.fa
    done
    cat tree-filtered/$hgt/bosTau7.fa > tree-filtered/$hgt/all.fa
    for species in `cat tree-filtered/$hgt.hit.spesies.txt |grep -v hit_species |awk '{print $1}'`
    do
	echo ">$species" >> tree-filtered/$hgt/all.fa
	grep -v ">" tree-filtered/$hgt/hit/$species.fa >> tree-filtered/$hgt/all.fa
    done
    muscle3.8.31_i86linux64 -quiet -in tree-filtered/$hgt/all.fa -out tree-filtered/$hgt/all.muscle # multiple alignment
    FastTreeMP -nt tree-filtered/$hgt/all.muscle > tree-filtered/$hgt/bosTau7.$hgt.tree # construct phylogenetic tree
done
