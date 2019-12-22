#!/usr/bin/perl -w
use strict;

my ($out,@files)= @ARGV;
die "usage: $0 <OUT Cov Files> <axt_format_files by BLASTZ (one target)>" if @ARGV<2;

open(OUT, ">$out")||die("error with writing to $out\n");
#print OUT "chr\tstart\tend\tidentity\ttarget_chr\tstart\tend\tstrand\tscore\n";

foreach my $file(@files){
    open(FILE,$file)||die("open $file error!\n");
    my ($chr1,$start1,$end1,$chr2,$start2,$end2,$strand2,$score,$query,$target,$identity) = ("","","","","","","","","","","");
    my $index = 0; ##line index
    while(<FILE>){
	chomp();
	if($_ !~ /#/ && $_ =~ /[^\s]/){
	    if($index%3 == 0){
		my @info = split(/\s+/);
		($chr1,$start1,$end1,$chr2,$start2,$end2,$strand2,$score) = ($info[1],$info[2],$info[3],$info[4],$info[5],$info[6],$info[7],$info[8]);
	    }
	    elsif($index%3 == 1){
		$query = uc($_);
	    }
	    else{
		$target = uc($_);
		my $len1 = length($query);
		my $len2 = length($target);
		my $score = 0;
		for(my $i=0;$i<$len1 && $i<$len2;$i++){
		    my $chr1 = substr($query,$i,1);
		    my $chr2 = substr($target,$i,1);
		    if($chr1 eq $chr2){
			$score += 1;
		    }
		}
		$identity = sprintf("%0.3f",$score/$len1);
		print OUT "$chr1\t$start1\t$end1\t$chr2\t$start2\t$end2\t$strand2\t$score\t$identity\n";
	    }
	    $index += 1;
	}
    }
    close FILE;
}

close OUT;

exit;
