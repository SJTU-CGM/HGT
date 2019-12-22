#!/usr/bin/perl -w
use strict;

## compute kmers of input FASTA file, foreach line

my ($fa,$kmer)= @ARGV;
die "Error with arguments!\nusage: $0 <Input fasta> <K-mer>\n" if (@ARGV<2);

open(FA,$fa)||die("error\n");

my %hash = ();
my @keys = ();
@keys = generateKmer($kmer,@keys);
foreach my $key(@keys){
    $hash{$key} = 0;
}

my $sum = 0;
my $id = "";
while(<FA>){
    chomp();
    if($_ =~ />([^\s]+)/){
	$id = $1;
    }
    if($_ !~ />/){
	my $seq = $_;
	my $len = length($seq);
	for(my $i=0;$i<$len-$kmer+1;$i++){
	    my $base = uc(substr($seq,$i,$kmer));
	    if(exists($hash{$base})){
		$hash{$base} += 1;
		$sum += 1;
	    }
	}
	if($sum > 0){
	    print "$id\t";
	    foreach my $key(@keys){
		$hash{$key} = sprintf("%0.4f",$hash{$key}/$sum);
		print "$hash{$key}\t";
	    }
	    print "\n";
	}
	foreach my $key(@keys){
	    $hash{$key} = 0;
	}
	$sum = 0;
    }
}

sub generateKmer{
    my ($order,@previous) = @_;
    my @append = ();

    if(@previous == 0){
	@append = ('A','T','C','G');
    }
    else{
	my @base = ('A','T','C','G');
	foreach my $item(@previous){
	    foreach my $char(@base){
		my $item2 = $item.$char;
		push(@append,$item2);
	    }
	}
    }

    $order -= 1;
    if($order == 0){
	return @append;
    }
    else{
	generateKmer($order,@append);
    }
}

sub GCpercentage{
    my ($seq) = @_;
    my ($A,$T,$C,$G) = (0,0,0,0);
    my $len = length($seq);
    for(my $i=0;$i<$len;$i++){
	my $base = substr($seq,$i,1);
	if($base eq 'A' || $base eq 'a'){
	    $A += 1;
	}
	elsif($base eq 'T' || $base eq 't'){
	    $T += 1;
	}
	elsif($base eq 'C' || $base eq 'c'){
	    $C += 1;
	}
	elsif($base eq 'G' || $base eq 'g'){
	    $G += 1;
	}
    }
    my $all = $A+$T+$C+$G;
    $A = sprintf("%0.2f",$A/$all);
    $T = sprintf("%0.2f",$T/$all);
    $C = sprintf("%0.2f",$C/$all);
    $G = sprintf("%0.2f",$G/$all);
    return ($A,$T,$C,$G);
}

close FA;
exit;
