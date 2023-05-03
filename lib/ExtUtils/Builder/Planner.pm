package ExtUtils::Builder::Planner;

use strict;
use warnings;

use Carp ();
use List::Util ();

use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Node;

sub new {
	my $class = shift;
	bless {
		nodes => {},
		roots => [],
	}, $class;
}

sub add_node {
	my ($self, $node) = @_;
	my $target = $node->target;
	Carp::croak("Duplicate for target $target") if exists $self->{nodes}{$target};
	$self->{nodes}{$target} = $node;
	return $node->target;
}

sub create_node {
	my ($self, %args) = @_;
	my $node = ExtUtils::Builder::Node->new(%args);
	$self->add_root($node->target) if $args{root};
	return $self->add_node($node);
}

sub add_root {
	my ($self, $root) = @_;
	push @{ $self->{roots} }, $root;
	return;
}

sub add_plan {
	my ($self, $plan) = @_;
	$self->add_node($_) for $plan->nodes;
	$self->add_root($_) for $plan->roots;
	return;
}

sub plan {
	my $self = shift;
	my %nodes = %{ $self->{nodes} };
	my @roots = List::Util::uniq(@{ $self->{roots} });
	return ExtUtils::Builder::Plan->new(nodes => \%nodes, roots => \@roots);
}

1;

# ABSTRACT: An ExtUtils::Builder Plan builder

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 $planner->create_node(
     target       => 'foo',
     dependencies => [ 'bar' ],
     actions      => \@actions,
     root         => 1,
 );
 my $plan = $planner->plan;

=head1 DESCRIPTION

=method new()

This creates a new planner object

=method add_node($node)

This adds an L<ExtUtils::Builder::Node|ExtUtils::Builder::Node> to the planner.

=method create_node(%args)

This creates a new node and adds it to the planner using C<add_node>. It takes the same named arguments as C<ExtUtils::Builder::Node>, except for an extra C<root> argument, which will cause the node to be added to the roots if true.

=method add_root($root)

This adds the given name to the list of roots.

=method add_plan($plan)

This adds all nodes and roots in the plan to the planner.

=method plan()

This returns a new L<ExtUtils::Builder::Plan|ExtUtils::Builder::Plan> object based on the planner.

=begin Pod::Coverage

new

=end Pod::Coverage
