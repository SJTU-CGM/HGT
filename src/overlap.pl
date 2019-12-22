#!/usr/bin/perl -w
use strict;

#overlap ids in two files

my ($id1,$id2)= @ARGV;
die "Error with arguments!\nusage: $0 <ID list 1> <ID list 2>, put out common IDs\n" if (@ARGV<2);

my %hash = ();

open(ID1,$id1)||die("error with opeing $id1\n");
open(ID2,$id2)||die("error with opeing $id2\n");

while(<ID1>){
    chomp();
    $hash{$_} = 1;
}
while(<ID2>){
    chomp();
    if(exists($hash{$_})){
	print "$_\n";
    }
}
close ID1;close ID2;
exit;
