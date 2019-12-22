#!/usr/bin/perl -w
use strict;

#overlap ids in two files

my ($id1,$id2)= @ARGV;
die "Error with arguments!\nusage: $0 <id1> <id2>, put out IDs in id2 only\n" if (@ARGV<2);

my %hash = ();

open(ID1,$id1)||die("error with opeing $id1\n");
open(ID2,$id2)||die("error with opeing $id2\n");
while(<ID1>){
    chomp();
    $hash{$_} = 1;
}

while(<ID2>){
    chomp();
    if(not exists($hash{$_})){
	print "$_\n";
    }
}
close ID1;close ID2;
exit;
