#!/usr/bin/perl

$m = @ARGV[0];

$xi = 0.0; # Analyzer angle for VV
$I0 = 1.0;
$Q0 = 1.0;

open(DEPOL, ">depolarization.dat");

for ($w=0; $w<=$m; $w++) {
	if ($w < 10) {
		$w_form = '00' . $w;
	} elsif ($w < 100) {
		$w_form = '0' . $w;
	} else {
		$w_form = $w;
	}

	$file_in = "w$w_form" . "r000" . ".avg";

	open(IN, $file_in);

	# Parse header.
	for ($i=0; $i < 12; $i++) {
		<IN>;
	}

	$wavelength_line = <IN>;

	($junk, $wavelength, $junk) = split(/=/, $wavelength_line, 3);

	$wavelength =~ s/\s//gi;
	$wavelength *= 1000.0;

	print "Calcating depolarization ratio at $wavelength nm.\n";

	# Parse header.
	for ($i=0; $i < 11; $i++) {
		<IN>;
	}

	$orient_angle_line = <IN>;
	($junk, $theta0, $junk) = split(/=/, $orient_angle_line, 3);
	$theta0 =~ s/\s//gi;

	for ($i=0; $i < 16; $i++) {
		<IN>;
	}

	$max_delta = 0;

	$phi_count = 0;
	while(<IN>) {
		$line = $_;
		chomp($line);
		$line =~ s/ +/;/gi;

		$first_char = substr($line, 0, 1);
		
		if ($first_char eq ';') {
			($junk, $theta[$phi_count], $phi, $pol, $s11, $s12, $s21, $s22, $s31, $s33, $s44, $s34, $s43) = split(/;/, $line);
		} else {
			(       $theta[$phi_count], $phi, $pol, $s11, $s12, $s21, $s22, $s31, $s33, $s44, $s34, $s43) = split(/;/, $line);
		}

		# Apply Mueller matrix to get scattered Stokes vector.
		$Is = ($s11 * $I0 + $s12 * $Q0);
		$Qs = ($s21 * $I0 + $s22 * $Q0);

		# Apply Mueller matrix for an ideal polarizer.
		$I_VV = 0.5 * ($Is + cos(2.0*$xi) * $Qs);
		$I_VH = 0.5 * ($Is + cos(2.0*($xi + 3.14159/2.0)) * $Qs);

		if ($I_VV == 0) {
			$I_VV = 1;
		}
		$delta[$phi_count] = $I_VH / $I_VV;


		# The calculation is only valid for theta = 0 because of the definition of
		# the incident Stokes vector.
		if ($theta[$phi_count] == 0) {
			print "Depolarization ratio @ 0 deg: " . $delta[$phi_count] . "\n";

			print DEPOL "$wavelength " . $delta[$phi_count] . "\n";
		}

		$phi_count++;
	}
	close(IN);
}

close(DEPOL);
exit;
