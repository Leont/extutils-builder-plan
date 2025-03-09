#!perl

use strict;
use warnings;

use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Planner;

my $planner = ExtUtils::Builder::Planner->new;
$planner->load_module("Callback");

plan skip_all => 'unimplemented';
