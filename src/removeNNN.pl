#!/usr/bin/perl -w
use strict;

#my ($fa,$ratio,$out)= @ARGV;
my ($fa,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <Input FASTA to remove NNN> <OUT File>\n" if (@ARGV<2);

open(FA,$fa)||die("error with opening $fa\n");
open(OUT,">$out")||die("error with writing to $out\n");

my $id = "";
while(<FA>){
    chomp();
    if($_=~ />/){
	$id = $_;
    }
    elsif(!($_ =~ /N/)){
	print OUT "$id\n$_\n";
    }
}


close FA;close OUT;
exit;
