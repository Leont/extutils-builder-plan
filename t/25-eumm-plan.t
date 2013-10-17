#! perl

use strict;
use warnings;

use Test::More 0.89;
use Test::Fatal;

use File::Temp qw/tempdir/;

system $^X, '-e0' and plan(skip_all => 'Can\'t find perl');

my $tempdir = tempdir();

chdir $tempdir;

open my $mfpl, '>', 'Makefile.PL';

print $mfpl <<'END';
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Plan;
use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Action::Command;

my $action = ExtUtils::Builder::Action::Command->new(command => [echo, 'very_unlikely_name']);
my $plan = ExtUtils::Builder::Plan->new(actions => [ $action ], dependencies => [], target => 'foo');

WriteMakefile(
	NAME => 'FOO',
	VERSION => 0.001,
	postamble => {
		plans => [ $plan ],
	},
);

END

close $mfpl;

system $^X, 'Makefile.PL';

ok(-e 'Makefile', 'Makefile exists');

open my $mf, '<', 'Makefile' or die "Couldn't open Makefile: $!";
my $content = do { local $/; <$mf> };

like($content, qr/^\t echo .* very_unlikely_name/xm, 'Makefile contains very_unlikely_name');

done_testing;
