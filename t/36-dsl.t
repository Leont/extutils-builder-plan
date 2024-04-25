#!perl

use strict;
use warnings;

use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Planner;

my $planner = ExtUtils::Builder::Planner->new;
$planner->run_dsl('t/dsl.pl');
my $plan = $planner->materialize;

lives_ok { $plan->execute } 'Executing gave no errors';

our @triggered;
is_deeply(\@triggered, [ 0..2 ], 'All actions triggered');

my %nodes;
my @order = qw/foo2 foo1 foo0/;
is_deeply([ $plan->node_names ], [ qw/foo foo0 foo1 foo2/ ], 'Got expected nodes');

done_testing;

