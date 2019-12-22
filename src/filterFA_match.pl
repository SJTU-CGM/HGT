#!/usr/bin/perl -w
use strict;

my ($file1,$file2,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <Fasta file> <ID.txt> <OUT>\n" if (@ARGV<3);

open(OUT,">$out")||die("Can't write to $out\n");
open(SEQ,$file1)||die("Can't open $file1\n");
open(ID,$file2)||die("Can't open $file2\n");

my %id=();
while(<ID>){
    chomp($_);
    if(not exists $id{$_}){
	$id{$_} = 1;
    }
    next;
}

my $id="";
my $id2 = "";
my $index = 0;
while(<SEQ>){
    chomp($_);
    if($_ =~ />/){
	if($_ =~ />([^\s]+)/){
	    $id = $1;
	    $id2 = $_;
	    $id2 =~ s/>//g;
	}
	if(exists $id{$id}){
	    $index = 1;
	}
	else{
	    $index = 0;
	}
    }
    elsif($index == 1){ #putout the sequence matchs
	print OUT ">$id2\n$_\n";
    }
    next;
}

close SEQ;close ID;close OUT;
exit;
