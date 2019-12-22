#!/usr/bin/perl -w
use strict;

## compare the kmer frequencies of hgt and seg, with hg19 as background

my ($background,$target,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <Background-kmer.txt (hg19, total)> <Target-kmer.txt> <OUT file>\n" if (@ARGV<3);

open(BACKGROUND,$background)||die("error\n");
open(TARGET,$target)||die("error\n");
open(OUT,">$out")||die("error\n");

my @genome = ();
while(<BACKGROUND>){
    chomp();
    @genome = split(/\s+/,$_);
    last;
}

print OUT "region\tdistance\n";
while(<TARGET>){
    chomp();
    my @data = split(/\s+/,$_);
    my $distance = 0;
    my $size = @genome;
    for(my $i=1;$i<$size;$i++){
	$distance += ($data[$i]-$genome[$i])**2;
    }
    $distance = sqrt($distance);
    print OUT "$data[0]\t$distance\n";
}

close BACKGROUND;close TARGET;close OUT;
exit;
