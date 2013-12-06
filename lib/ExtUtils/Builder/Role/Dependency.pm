package ExtUtils::Builder::Role::Dependency;

use Moo::Role;

has target => (
	is       => 'ro',
	required => 1,
);

has _dependencies => (
	is       => 'ro',
	required => 1,
	init_arg => 'dependencies',
);

sub dependencies {
	my $self = shift;
	return @{ $self->_dependencies };
}

1;

# ABSTRACT: A role for dependency classes

=head1 DESCRIPTION

This role defines a relationship between one target and zero or more dependencies.

=attr target

The name of the target in this relationship.

=attr dependencies

A list of names of dependencies.
