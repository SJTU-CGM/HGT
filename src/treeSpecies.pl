#!/usr/bin/perl -w
use strict;

my ($hit,$type)= @ARGV;
die "Error with arguments!\nusage: $0 <cov-hit.txt> <type.txt>\n" if (@ARGV<2);

open(HIT,$hit)||die("error\n");
open(TYPE,$type)||die("error\n");

my %hash = ();
while(<TYPE>){
    chomp();
    my @arr = split(/\s+/,$_);
    $hash{$arr[0]} = $arr[1];
}

my ($fungi,$plant,$protozoa,$invertebrate,$vertebrate_other,$vertebrate_mammalian,$species) = (0,0,0,0,0,0,0);

while(<HIT>){
    chomp();
    my @arr = split(/\s+/,$_);
    if(exists($hash{$arr[0]})){
	if($hash{$arr[0]} eq "fungi"){
	    $fungi++;
	}
	elsif($hash{$arr[0]} eq "plant"){
            $plant++;
        }
	elsif($hash{$arr[0]} eq "protozoa"){
            $protozoa++;
        }
	elsif($hash{$arr[0]} eq "invertebrate"){
            $invertebrate++;
        }
	elsif($hash{$arr[0]} eq "vertebrate_other"){
            $vertebrate_other++;
        }
	elsif($hash{$arr[0]} eq "vertebrate_mammalian"){
            $vertebrate_mammalian++;
        }
    }
}

$species = $fungi+$plant+$protozoa+$invertebrate+$vertebrate_other+$vertebrate_mammalian;
print "$fungi\t$plant\t$protozoa\t$invertebrate\t$vertebrate_other\t$vertebrate_mammalian\t$species\n";

close HIT;close TYPE;
exit;
