package ExtUtils::Builder::Plan;

use Moo;
use Carp ();

with 'ExtUtils::Builder::Role::Action::Composite';

has _nodes => (
	is => 'ro',
	init_arg => 'nodes',
	default => sub { [] },
	coerce => sub {
		return +{ map { $_->target => $_ } @{ $_[0] } };
	}
);

sub nodes {
	my $self = shift;
	return values %{ $self->_nodes };
}

has _roots => (
	is => 'ro',
	init_arg => 'roots',
	required => 1,
	coerce => sub {
		return ref($_[0]) eq 'ARRAY' ? $_[0] : [ $_[0] ];
	}
);

sub roots {
	my $self = shift;
	return @{ $self->_roots };
}

sub _node_sorter {
	my ($self, $name, $callback, $seen, $loop) = @_;
	Carp::croak("$name has a circular dependency, aborting!\n") if exists $loop->{$name};
	return if $seen->{$name}++;
	my $node = $self->_nodes->{$name} or Carp::confess("Node $name doesn't exist");
	local $loop->{$name} = 1;
	$self->_node_sorter($_, $callback, $seen, $loop) for $node->dependencies;
	$callback->($name, $node);
	return;
}

around execute => sub {
	my ($orig, $self, %options) = @_;
	my @seenloop = ({}, {});
	my $run_node = sub {
		my ($name, $node) = @_;
		return if -e $name and sub { -d $_ or -M $name <= -M $_ or return 0 for sort $node->dependencies; 1 }->();
		$node->execute(%options);
	};
	$self->_node_sorter($_, $run_node, @seenloop) for $self->roots;
	return;
};

sub flatten {
	my $self = shift;
	my @ret;
	my @seenloop = ({}, {});
	$self->_node_sorter($_, sub { push @ret, $_[1]->flatten }, @seenloop) for $self->roots;
	return @ret;
}

1;

# ABSTRACT: An ExtUtils::Builder Plan

=head1 SYNOPSIS

 my $plan = Frobnicate->new->plan;
 $plan->execute;
 say $_->target for $plan->nodes;
 $backend->consume($plan);

=head1 DESCRIPTION

This module a process. It contains one or more nodes, at least one of which is declared a root node. This is enough to describe whole building processes, in fact its <execute> method is a tiny C<make> engine. It also happens to be a full-blown L<action|ExtUtils::Builder::Role::Action>, but you're unlikely to want to use it like that.

=attr nodes

This is the set of all nodes in this plan.

=attr roots

This list contains one or more names of the roots of the process. This will be used as a starting point when running it.

=method execute

This runs the process. Similar to C<make>, it checks for each node if it is necessary to run, and if not skips it.

=method flatten

This flattens the plan, returning the actions in the nodes of the plan in a correct order.

=method to_command

Returns all commands in all actions in the nodes of the plan in a correct order.

=method to_code

Returns all code-strings in all actions in the nodes of the plan in a correct order.
