#!/usr/bin/perl -w
use strict;

#compare two bed files, used to get the overlapped regions (the files should be sorted accoridng to the col0 and col1)

my ($bed1,$bed2)= @ARGV;
die "Error with arguments!\nusage: $0 <BED File 1 (search database)> <BED File2 (target)>\n" if (@ARGV<2);
#file format: chr start end [other infomation] (the files were previously sorted)

open(BED1,$bed1)||die("error with opeing $bed1\n");
open(BED2,$bed2)||die("error with opening $bed2\n");
#open(OUT,">$out")||die("error with writing to $out\n");

my @data = ();
my $num = 0;
my $size = 0;
while(<BED1>){
    chomp();
    my @arr = split(/\s+/,$_);
    $size = @arr;
    for(my $j=0;$j<@arr;$j++){
	$data[$num][$j] = $arr[$j];
    }
    $num += 1;
    next;
}

my $index = 0;
while(<BED2>){
    chomp();
    my @arr = split(/\s+/,$_);
    my $index_update = 0; ## whether the index is updated after this record;
    my ($chr,$start,$end) = ($arr[0],$arr[1],$arr[2]);
    for(my $i=$index;$i<$num;$i++){
	if($chr lt $data[$i][0] || ($chr eq $data[$i][0] && $end <= $data[$i][1])){
	    if($index_update == 0){
		$index = $i;
	    }
	    last;
	}
	elsif($chr eq $data[$i][0] && (!($start >= $data[$i][2]))){ #overlap
	    #print OUT "$_ ; ";
	    print  "$_ ; ";
	    for(my $j=0;$j<$size;$j++){
		if($j==$size-1){
		    #print OUT "$data[$i][$j]\n";
		    print "$data[$i][$j]\n";
		}
		else{
		    #print OUT "$data[$i][$j]\t";
		    print "$data[$i][$j]\t";
		}
	    }
	    if($index_update == 0){
		$index = $i; #update the index position
		$index_update = 1;
	    }
	}
    }
}

close BED1;close BED2;
#close OUT;
exit;
