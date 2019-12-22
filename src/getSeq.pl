#!/usr/bin/perl -w
use strict;

my ($fa,$bed,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <Genome.fa> <HGT.bed> <OUT File>\n" if (@ARGV<3);

open(FA,$fa)||die("error with opening $fa\n");
open(BED,$bed)||die("error with opening $bed\n");
open(OUT,">$out")||die("error with writing to $out\n");

my %hash = ();
my $id = "";
while(<FA>){
    chomp();
    if($_ =~ />([^\s]+)/){
	$id = $1;
    }
    else{
	$hash{$id} = $_;
    }
}

while(<BED>){
    chomp();
    my @arr = split(/\s+/,$_);
    my ($chr,$start,$end,$strand) = ($arr[0],$arr[1],$arr[2],$arr[3]);
    my $HGT = "";
    if($strand eq "+"){
	$HGT = uc(substr($hash{$chr},$start-1,$end-$start+1));
    }
    else{
	my $complement = reverse_complement_IUPAC($hash{$chr});
	$HGT = uc(substr($complement,$start-1,$end-$start+1));
    }
    print OUT ">$chr|$start-$end|$strand\n$HGT\n";
}

sub reverse_complement_IUPAC {         
    my ($dna) = @_;          
# reverse the DNA sequence       
    my $revcomp = reverse($dna);
    # complement the reversed DNA sequence
    #$revcomp =~ tr/ACGTacgt/TGCAtgca/;
    $revcomp =~ tr/ABCDGHMNRSTUVWXYabcdghmnrstuvwxy/TVGHCDKNYSAABWXRtvghcdknysaabwxr/;
    return $revcomp;
}

close FA;close BED;close OUT;
exit;
