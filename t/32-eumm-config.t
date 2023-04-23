#! perl

use strict;
use warnings;

use ExtUtils::MakeMaker::Config;
use Test::More 0.89;

use ExtUtils::Builder::MakeMaker::Config;

my $value = "$Config{ccflags} -Whatever";
my %makemaker = (CCFLAGS => $value);

my $config = ExtUtils::Builder::MakeMaker::Config->new(\%makemaker);

is($config->get('optimize'), $Config{optimize});
is($config->get('ccflags'), $value);
is_deeply($config->values_set, { ccflags => $value });
is_deeply($config->all_config, { %Config, ccflags => $value });

done_testing;
