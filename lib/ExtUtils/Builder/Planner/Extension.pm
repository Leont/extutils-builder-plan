package ExtUtils::Builder::Planner::Extension;

use strict;
use warnings;

sub add_delegate {
	my ($self, $planner, $as, $make_node) = @_;
	my $delegate = sub {
		my ($self, @args) = @_;
		for my $node ($make_node->(@args)) {
			$planner->add_node($node);
		}
	};
	$planner->add_delegate($as, $delegate);
	return;
}

1;

#ABSTRACT: a base class for Planner extensions

=method add_delegate($planner, $as, $make_node)

This adds a delegate function to C<$planner> with name C<$name>. The function must return zero or more L<node|ExtUtils::Builder::Node> objects that will be added to the plan.
