package ExtUtils::Builder::Action::Composite;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Action';

sub _preference_map {
	return {
		flatten => 3,
		execute => 2,
		command => 1,
		code    => 0,
	};
}

sub execute {
	my ($self, %opts) = @_;
	$_->execute(%opts) for $self->flatten(%opts);
	return;
}

sub to_code {
	my ($self, %opts) = @_;
	return map { $_->to_code(%opts) } $self->flatten(%opts);
}

sub to_command {
	my ($self, %opts) = @_;
	return map { $_->to_command(%opts) } $self->flatten(%opts);
}

1;

# ABSTRACT: A base role for composite action classes

=head1 DESCRIPTION

This is a base-role for all composite action classes

=method preference

This will prefer handling methods in the following order: flatten, execute, command, code

=method execute

Execute all actions in this collection.

=method to_command

This returns the list commands of all actions in the collection.

=method to_code

This returns the list of evaluatable strings of all actions in the collection.

=method preference

This will prefer handling methods in the following order: flatten, execute, command, code
