#! perl

use strict;
use warnings;

use Test::More 0.89;
use Test::Fatal;

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Action::Code;

my ($node, @triggered);
my @actions = map { my $num = $_; ExtUtils::Builder::Action::Code->new(code => sub { push @triggered, $num }) } 1, 2;
is(exception { $node = ExtUtils::Builder::Node->new(target => 'foo', dependencies => [ qw/bar baz/ ], actions => \@actions) }, undef, 'Can create new object');

is(exception { $node->execute }, undef, 'Can execute quiet command');
is_deeply(\@triggered, [ 1, 2 ], 'Both actions ran');
is_deeply([ $node->flatten ], \@actions, '$node->actions contains all expected actions');
is(exception { $node->to_command }, undef, '$node->to_command doesn\'t give any error');
is($node->preference, 'flatten', 'Preferred action is "flatten"');

done_testing;
