#! perl

use strict;
use warnings;

use Test::More 0.89;
use Test::Fatal;

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Action::Code;

my @triggered;
my @nodes = map { my $num = $_; ExtUtils::Builder::Node->new(target => "foo$_", dependencies => [], actions => [ ExtUtils::Builder::Action::Code->new(code => sub { push @triggered, $num }) ]) } 0 .. 2;
my $root = ExtUtils::Builder::Node->new(target => "foo", dependencies => [ map { "foo$_" } 0..2 ], actions => []);
my $plan;
is(exception { $plan = ExtUtils::Builder::Plan->new(nodes => [ @nodes, $root ], roots => 'foo') }, undef, 'Plan could be created');

is(exception { $plan->execute }, undef, 'executing gave no errors');

is_deeply(\@triggered, [ 0..2 ], 'All actions triggered');

done_testing;


