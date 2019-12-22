#!/usr/bin/perl -w
use strict;

my ($hit,$start,$end,$coverage,$vertebrate_mammalian,$iden_remote,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <cov.txt> <start position> <end position> <coverage> <vertebrate_mammalian.id> <identity for remote hits> <OUT FILE>\n" if (@ARGV<7);

open(FILE,$hit)||die("error with opening $hit\n");
open(OUT,">$out")||die("error with writing to $out\n");

my %close = ();
open(Mammalian,$vertebrate_mammalian)||die("error with opening $vertebrate_mammalian\n");
while(<Mammalian>){
    chomp();
    $close{$_} = 1;
}

while(<FILE>){
    chomp();
    my @arr = split(/\s+/,$_);
    ### for close and remote species, the identity setting is different
    if( ($arr[8] >= $iden_remote && not exists($close{$arr[0]})) || exists($close{$arr[0]})){
	if(!($arr[1] >= $end || $arr[2] <= $start)){
	    my ($start_new,$end_new) = ($start,$end);
	    if($arr[1] > $start){
		$start_new = $arr[1];
	    }
	    if($arr[2] < $end){
		$end_new = $arr[2];
	    }
	    
	    my $cov = ($end_new-$start_new+1)/($end-$start+1);
	    if($cov >= $coverage){
		print OUT "$_\n";
	    }
	}
    }
}

close FILE;close OUT;
exit;
