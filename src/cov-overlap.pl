#!/usr/bin/perl -w
use strict;

my ($hit,$hgt,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <cov-hit.txt> <HGT region> <OUT FILE>\n" if (@ARGV<3);

open(FILE,$hit);
open(OUT,">$out")||die("error\n");

my ($chr_hgt,$start_hgt,$end_hgt) = split(/\-/,$hgt);

print OUT "hit_species\tchr\tstart\tend\tstrand\tidentity\n";
while(<FILE>){
    chomp();
    my ($id,$chr,$start,$end,$strand,$iden,$start_match,$end_match) = split(/\s+/,$_);
    if($start_match < $start_hgt){
	if($end_match <= $end_hgt){
	    my $ratio = ($end_match-$start_hgt+1)/($end_match-$start_match+1);
	    my $len_new = int($ratio*($end-$start+1));
	    $start_match = $start_hgt;
	    $start = $end-$len_new+1;
	}
	else{
	    my $ratio = ($end_hgt-$start_hgt+1)/($end_match-$start_match+1);
	    my $len_change_left = int(($start_hgt-$start_match+1)/($end_match-$start_match+1)*($end-$start+1));
	    my $len_change_right = int(($end_match-$end_hgt+1)/($end_match-$start_match+1)*($end-$start+1));
	    $start_match = $start_hgt;
	    $end_match = $end_hgt;
	    $start = $start + $len_change_left;
	    $end = $end - $len_change_right;
	}
    }
    else{
	if($end_match > $end_hgt){
	    my $ratio = ($end_hgt-$start_match+1)/($end_match-$start_match+1);
	    my $len_new = int($ratio*($end-$start+1));
	    $end_match = $end_hgt;
	    $end = $start+$len_new-1;
        }
    }
    print OUT "$id\t$chr\t$start\t$end\t$strand\t$iden\n";
}

close FILE;close OUT;
exit;
