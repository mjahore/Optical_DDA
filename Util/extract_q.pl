#!/usr/bin/perl

$file_in = @ARGV[0];

open(IN, $file_in);
open(OUT, ">cross-section.dat");

# Burn through the header.
for ($i=0; $i<14; $i++) {
	$junk = <IN>;
}

# Look through the rest and pull out scattering/extinction.
while(<IN>){
	$line = $_;
	chomp($line);

	($junk, $alpha, $lambda, $Qext, $Qabs, $Qsca, $junk) = split(/\s{1}/, $line, 7);

	print OUT "$lambda $Qext $Qabs $Qsca\n";
}

close(IN);
close(OUT);
exit;
