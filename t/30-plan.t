#! perl

use strict;
use warnings;

use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Action::Code;

our @triggered;
my @nodes = map {
	ExtUtils::Builder::Node->new(
		target => "foo$_",
		dependencies => [],
		actions => [ ExtUtils::Builder::Action::Code->new(code => "push \@::triggered, $_" ) ]
	)
} 0 .. 2;

my $root = ExtUtils::Builder::Node->new(target => "foo", dependencies => [ map { "foo$_" } 0..2 ], actions => []);
my $plan;
lives_ok { $plan = ExtUtils::Builder::Plan->new(nodes => [ @nodes, $root ], roots => 'foo') } 'Plan could be created';

lives_ok { $plan->execute } 'Executing gave no errors';

is_deeply(\@triggered, [ 0..2 ], 'All actions triggered');

is_deeply([ sort $plan->nodes ], [ sort @nodes, $root ], 'Got expected nodes');

is_deeply([ $plan->flatten ], [ map { $_->flatten } @nodes, $root ], 'flattens to (@nodes, $root)');

done_testing;


