package ExtUtils::Builder::Plan;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use base 'ExtUtils::Builder::Action::Composite';

sub new {
	my ($class, %args) = @_;
	Carp::croak('Attribute roots is required') if not defined $args{roots};
	$args{roots} = [ $args{roots} ] if ref($args{roots}) ne 'ARRAY';
	$args{nodes} ||= {};
	return $class->SUPER::new(%args);
}

sub node {
	my ($self, $name) = @_;
	return $self->{nodes}{$name};
}

sub nodes {
	my $self = shift;
	return @{$self->{nodes}}{ $self->node_names };
}

sub node_names {
	my $self = shift;
	return sort keys %{ $self->{nodes} };
}

sub roots {
	my $self = shift;
	return @{ $self->{roots} };
}

sub _node_sorter {
	my ($self, $name, $callback, $seen, $loop) = @_;
	Carp::croak("$name has a circular dependency, aborting!\n") if exists $loop->{$name};
	return if $seen->{$name}++;
	if (my $node = $self->{nodes}{$name}) {
		local $loop->{$name} = 1;
		$self->_node_sorter($_, $callback, $seen, $loop) for $node->dependencies;
		$callback->($name, $node);
	} elsif (not -e $name) {
		Carp::confess("Node $name doesn't exist")
	}
	return;
}

sub _flat {
	my $args = shift;
	return ref($args) ? @{ $args } : $args;
}

sub execute {
	my ($self, %options) = @_;
	my (%seen, %loop);
	my @targets = $options{targets} ? _flat($options{targets}) : $self->roots;
	my $run_node = sub {
		my ($name, $node) = @_;
		return if not $node->phony and -e $name and sub { -d or -M $name <= -M or return 0 for sort $node->dependencies; 1 }->();
		$node->execute(%options);
	};
	$self->_node_sorter($_, $run_node, \%seen, \%loop) for @targets;
	return;
}

sub flatten {
	my ($self, %options) = @_;
	my (@ret, %seen, %loop);
	my @targets = $options{targets} ? _flat($options{targets}) : $self->roots;
	$self->_node_sorter($_, sub { push @ret, $_[1]->flatten }, \%seen, \%loop) for @targets;
	return @ret;
}

sub merge {
	my ($self, $other) = @_;
	Carp::croak('Right side of merge is not a Plan') if not $other->isa(__PACKAGE__);
	my $double = join ', ', grep { $other->{nodes}{$_} } keys %{ $self->{nodes} };
	Carp::croak("Found key(s) $double on both sides of merge") if $double;
	my %nodes = (%{ $self->{nodes} }, %{ $other->{nodes} });
	my @roots = Scalar::Util::uniq(@{ $self->{roots} }, @{ $other->{roots} });
	return ref($self)->new(nodes => [ values %nodes ], roots => \@roots);
}

sub phonies {
	my ($self) = @_;
	return sort map { $_->target } grep { $_->phony } values %{ $self->{nodes} };
}

1;

# ABSTRACT: An ExtUtils::Builder Plan

=head1 SYNOPSIS

 package Frobnicate;
 sub plan {
     my %nodes = ...;
     return ExtUtils::Builder::Plan->new(
         roots => [ 'foo' ],
         nodes => \%nodes,
     );
 }

 my $plan = Frobnicate->plan(@args);
 
 # various consumption methods
 $plan->execute;
 say $_->target for $plan->nodes;

=head1 DESCRIPTION

An object of this class describes a process. It contains one or more nodes, at least one of which is declared a root node. This is enough to describe whole building processes, in fact its <execute> method is a tiny C<make> engine. It also happens to be a full-blown L<action|ExtUtils::Builder::Action>, but you're unlikely to want to use it like that.

=attr nodes

This is the set of all nodes in this plan.

=attr roots

This list contains one or more names of the roots of the process. This will be used as a starting point when running it.

=method execute

This runs the process. Similar to C<make>, it checks for each node if it is necessary to run, and if not skips it.

=method flatten(targets => \@targets)

This flattens the plan, returning the actions in the nodes of the plan in a correct order. If targets is given those targets will be processed, otherwise the roots will be.

=method to_command

Returns all commands in all actions in the nodes of the plan in a correct order.

=method to_code

Returns all code-strings in all actions in the nodes of the plan in a correct order.

=method node($target)

Returns the node for the specified C<$target>.

=method node_names()

Returns the names of all the nodes.

=method merge($other)

This merges this plan with another, and returns the new plan. Each entry may only exist on one side of the merge.

=method phonies()

This returns the names of all phony targets.

=begin Pod::Coverage

new

=end Pod::Coverage
