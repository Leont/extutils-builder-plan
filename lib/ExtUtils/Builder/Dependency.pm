package ExtUtils::Builder::Dependency;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless \%args, $class;
}

sub target {
	my $self = shift;
	return $self->{target};
}

sub dependencies {
	my $self = shift;
	return @{ $self->{dependencies} };
}

1;

# ABSTRACT: A role for dependency classes

=head1 DESCRIPTION

This role defines a relationship between one target and zero or more dependencies.

=attr target

The name of the target in this relationship.

=attr dependencies

A list of names of dependencies.
