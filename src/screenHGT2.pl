#!/usr/bin/perl -w
use strict;

my ($remote,$out,$cov_cuttof,@files)= @ARGV;
die "Error with arguments!\nusage: $0 <Nonmammal conserved regions (bed)> <OUT File> <length coverage cuttof> <Merged mammal files>\n" if (@ARGV<4);

### filtering HGTs with bed files (remote & close both)


open(REMOTE,$remote)||die("error\n with opening $remote");
open(OUT,">$out")||die("error with writing to $out\n");


while(<REMOTE>){
   chomp();
   my ($chr_this,$start_this,$end_this) = split(/\s+/,$_);
   my $length_this = $end_this-$start_this+1;
   my $cov_species = 0;
   
   foreach my $file(@files){
       open(FILE,$file)||die("error with opening $file\n");
       my $cov_length = 0;

       while(<FILE>){
	   chomp();
	   my ($chr,$start,$end) = split(/\s+/,$_);
	   if($chr gt $chr_this){
	       last;
	   }
	   elsif($chr eq $chr_this){
	       if($start >= $end_this){
		   last;
	       }
	       elsif(!($end <= $start_this)){
		   my ($cov_start,$cov_end) = ($start_this,$end_this);
		   if($start > $cov_start){$cov_start = $start;}
		   if($end < $cov_end){$cov_end = $end;}
		   $cov_length += $cov_end-$cov_start+1;
	       }
	   }
       }
       if($cov_length/$length_this >= $cov_cuttof){
	   $cov_species += 1;
       }
       close FILE;
   }
   print OUT "$chr_this\t$start_this\t$end_this\t$cov_species\n";
}

close REMOTE;close OUT;
exit;
