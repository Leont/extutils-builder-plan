#! perl

use strict;
use warnings;

use Test::More 0.89;

use Config;
use File::Temp qw/tempdir/;

system $^X, '-e0' and plan(skip_all => 'Can\'t find perl');

my $tempdir = tempdir();

chdir $tempdir;

open my $mfpl, '>', 'Makefile.PL';

my @touch_prefix = $^O eq 'MSWin32' || $^O eq 'VMS' ? ($^X, '-MExtUtils::Command', '-e') : ();
my $touch = join ', ', map { qq{'$_'} } @touch_prefix, 'touch';

printf $mfpl <<'END', $touch;
use ExtUtils::MakeMaker;
use ExtUtils::Builder::MakeMaker -global;
use ExtUtils::Builder::Node;
use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Action::Command;

my $action = ExtUtils::Builder::Action::Command->new(command => [%s, 'very_unlikely_name']);
my $node = ExtUtils::Builder::Node->new(actions => [ $action ], dependencies => [], target => 'foo');
my $plan = ExtUtils::Builder::Plan->new(nodes => [ $node ], roots => 'foo');

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

like($content, qr/^\t .* touch .* very_unlikely_name/xm, 'Makefile contains very_unlikely_name');

my $make = $ENV{MAKE} || $Config{make};
system $make;
ok(-e 'very_unlikely_name', "Unlikely file has been touched");

done_testing;
