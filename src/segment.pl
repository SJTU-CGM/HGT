#!/usr/bin/perl -w
use strict;

#generate segments from genome

my ($fa,$len,$step,$out)= @ARGV;
die "Error with arguments!\nusage: $0 <Genome.fa> <Segments length> <step length> <OUT File>\n" if (@ARGV<4);

open(FA,$fa)||die("error\n");
open(OUT,">$out")||die("error\n");

my $id = "";
while(<FA>){
    chomp();
    if($_ =~ />([^\s]+)/){
	$id = $1;
    }
    else{
	my $length = length($_);
	for(my $i=0;$i<$length-$len;){
	    my $seq = substr($_,$i,$len);
	    my ($start,$end) = ($i+1,$i+$len);
	    print OUT ">$id-$start-$end\n$seq\n";
	    $i += $step
	}
    }
}

close FA;close OUT;
exit;
