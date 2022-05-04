#use warnings;
use strict;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

my %sitehash;
my %totalhash;
my %lvlhash;

my $minsamps = 60;
my $mincov = 20;

foreach my $file (glob "*.rnaediting_op") {
	my @names = split(/\./,$file);
	my $sample = $names[0];
	my $strain = join '-', (split(/-/, $sample))[0], (split(/-/, $sample))[1];
	open (my $INPUT, "<", $file);
	while(<$INPUT>) {
		chomp;
		my @fields = split;
		my ($chr, $pos, $cov, $edit, $lvl) = ($fields[0],$fields[1],$fields[3], $fields[4],$fields[5]);
		my $site = join ':', $chr, ($pos-1), $pos;
		my $ratio = join '/', $edit, $cov;
		next if ($chr eq '#chrom');
		if ($cov >= $mincov) {
			$sitehash{$strain}{$site} = $ratio;
			if ($totalhash{$site}) {
				$totalhash{$site}++;
				$lvlhash{$site} = join ',', $lvlhash{$site}, $ratio;
			} else {
				$totalhash{$site} = 1;
				$lvlhash{$site} = $ratio;
			}
		}
	}
	close $INPUT;
}

print "chrom";
foreach my $strain (keys %sitehash) {
	print " $strain";
}
print "\n";
foreach my $site (keys %totalhash) {
	if ($totalhash{$site} >= $minsamps) {
		my @lvls = split(/\,/, $lvlhash{$site});
		@lvls = sort {$b <=> $a} @lvls;
		
			print "$site";
			foreach my $strain (keys %sitehash) {
				if ($sitehash{$strain}{$site}) {
					print " $sitehash{$strain}{$site}";
				} else {
					print " 0/0";
				}
			}
			print "\n";
		
	}
}
