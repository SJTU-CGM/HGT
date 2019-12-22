#!/usr/bin/perl -w
use strict;

## cov -> covBed file

my ($in)= @ARGV;
die "Error with arguments!\nusage: $0 <xxx.cov>" if (@ARGV<1);

open(IN,$in)||die("error with opening $in\n");

while(<IN>){
    chomp();
    my @arr = split(/\s+/,$_);
    my @data = split(/-/,$arr[0]);
    my ($chr,$start,$end) = ($data[0],$data[1]+$arr[1]-1,$data[1]+$arr[2]-1);
    print "$chr\t$start\t$end\t$arr[3]\t$arr[4]\t$arr[5]\t$arr[6]\t$arr[7]\t$arr[8]\n";
}

close IN;
exit;
