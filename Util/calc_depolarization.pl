#!/usr/bin/perl

$m = @ARGV[0];
$n = @ARGV[1];

$D_rot = 3000.0; #Units: s^-1

open(DEPOL_90, ">delta_90.dat");

for ($w=0; $w<$m; $w++) {
for ($k=0; $k<$n; $k++) {
	if ($k < 10) {
		$k_form = '00' . $k;
	} elsif ($k < 100) {
		$k_form = '0' . $k;
	} else {
		$k_form = $k;
	}

	if ($w < 10) {
		$w_form = '00' . $w;
	} elsif ($w < 100) {
		$w_form = '0' . $w;
	} else {
		$w_form = $w;
	}

	$file_in = "w$w_form" . "r000" . "k$k_form" . ".sca";

	open(IN, $file_in);

	# Parse header.
	for ($i=0; $i < 16; $i++) {
		<IN>;
	}

	$wavelength_line = <IN>;

	($junk, $wavelength, $junk) = split(/=/, $wavelength_line, 3);

	$wavelength =~ s/\s//gi;
	$wavelength *= 1000.0;

	print "Calcating depolarization ratio at $wavelength nm.\n";
	open(DEPOL_RATIO, ">>depolarization_$wavelength.dat");

	# Parse header.
	for ($i=0; $i < 16; $i++) {
		<IN>;
	}

	$orient_angle_line = <IN>;
	($junk, $theta0, $junk) = split(/=/, $orient_angle_line, 3);
	$theta0 =~ s/\s//gi;

	print "Calculating for angle $theta0.\n";

	$file_stub = ">depol_" . $w . "_$theta0.dpl";

	open(OUT, $file_stub);
	for ($i=0; $i < 13; $i++) {
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

		# For this calculation, see A. Ben-David, J. Geophys. Res. 1998, 103, 26041-26050.
		$m11 = $s11;
		$m22 = ($s22 - $s33)/2.0;
		$m33 = -$m22;
		$b22 = ($m22 + abs($m33))/2.0;
	
		$delta[$phi_count] = (1 - $b22/$m11) / (1 + $b22/$m11);
		if ($delta[$phi_count] > $max_delta) {
			$max_delta = $delta[$phi_count];
		}

		print OUT $theta[$phi_count] . " $phi $wavelength " . $delta[$phi_count] ."\n";

		if ($theta[$phi_count] == 0) {
			$pseudo_time = 1.0/sqrt(6.0 * $D_rot) * ($theta0 * 3.14159/180.0)**2;
			print "Depolarization ratio @ 0 deg: " . $delta[$phi_count] . "\n";
			print DEPOL_RATIO "$pseudo_time $theta0 " . $delta[$phi_count] . "\n";

			if ($theta0 == 90) {
				print DEPOL_90 "$wavelength " . $delta[$phi_count] . "\n";
			}
		}

		$phi_count++;
	}
	close(OUT);
	close(DEPOL_RATIO);

	$file_stub = ">depol_" . $w . "_$theta0.nml";
	open(OUT, $file_stub);
	for ($i=0; $i<$phi_count; $i++) {
		print OUT $theta[$i] . " " . $delta[$i]/$max_delta . "\n";
	}
	close(OUT);
	close(IN);
}
}
close(DEPOL_90);
exit;
