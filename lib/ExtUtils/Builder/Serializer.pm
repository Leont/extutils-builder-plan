package ExtUtils::Builder::Serializer;

use strict;
use warnings;

use Carp 'croak';

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Action::Code;
use ExtUtils::Builder::Node;
use ExtUtils::Builder::Plan;

sub serialize_plan {
	my ($self, $plan) = @_;

	my %nodes;
	for my $node_name ($plan->node_names) {
		$nodes{$node_name} = $self->serialize_node($plan->node($node_name));
	}

	return {
		nodes => \%nodes,
	}
}

sub serialize_node {
	my ($self, $node, %opts) = @_;
	my @actions = map { $self->serialize_action($_, %opts) } $node->flatten;
	return {
		dependencies => [ $node->dependencies ],
		actions      => \@actions,
		phony        => $node->phony,
	}
}

sub serialize_action {
	my ($self, $action, %opts) = @_;
	my $preference = $action->preference('code', 'command');
	my $method = $preference eq 'code' ? 'serialize_code' : 'serialize_command';
	return $self->$method($action, %opts);
}

sub serialize_code {
	my ($self, $action, %opts) = @_;
	return [ 'code', $action->to_code_hash(%opts) ];
}

sub serialize_command {
	my ($self, $action, %opts) = @_;
	return map { [ 'command', $_ ] } $action->to_command(%opts)
}


sub deserialize_plan {
	my ($self, $serialized, %options) = @_;

	my %nodes;
	for my $node_name (keys %{ $serialized->{nodes} }) {
		$nodes{$node_name} = $self->deserialize_node($node_name, $serialized->{nodes}{$node_name}, %options);
	}

	return ExtUtils::Builder::Plan->new(
		nodes => \%nodes,
	);
}

sub deserialize_node {
	my ($self, $name, $serialized, %options) = @_;

	my @actions = map { $self->deserialize_action($_, %options) } @{ $serialized->{actions} };

	return ExtUtils::Builder::Node->new(
		target       => $name,
		dependencies => [ @{ $serialized->{dependencies} } ],
		actions      => \@actions,
		phony        => $serialized->{phony},
	);
}

sub deserialize_action {
	my ($self, $serialized, %options) = @_;
	my ($command, @args) = @{$serialized};

	if ($command eq 'command') {
		return ExtUtils::Builder::Action::Command->new(command => $args[0]);
	} elsif ($command eq 'code') {
		return map { ExtUtils::Builder::Action::Code->new(%$_) } @args;
	} else {
		croak "Unknown serialized command $command";
	}
}

1;

#ABSTRACT: 

=head1 DESCRIPTION

XXX

=method serialize_plan($plan)

Serialize a plan into a JSON compatible hash structure.

=method serialize_node($node)

Serialize a node into a JSON compatible hash structure.

=method serialize_action($action)

Serialize an action into a JSON compatible hash structure.

=method serialize_code($action)

Serialize a code action into a JSON compatible hash structure.

=method serialize_command($action)

Serialize a command action into a JSON compatible hash structure.

=method deserialize_plan($plan)

Deserialize a plan from a JSON compatible hash structure.

=method deserialize_node($node)

Deserialize a node from a JSON compatible hash structure.

=method deserialize_action($action)

Deserialize an action from a JSON compatible hash structure.
