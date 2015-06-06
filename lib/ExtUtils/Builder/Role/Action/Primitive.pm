package ExtUtils::Builder::Role::Action::Primitive;

use strict;
use warnings;

use base 'ExtUtils::Builder::Role::Action';

sub flatten {
	my $self = shift;
	return $self;
}

1;

# ABSTRACT: A base role for primitive action classes

=head1 DESCRIPTION

This is a base role for primitive action classes such as L<Code|ExtUtils::Builder::Action::Code> and L<Command|ExtUtils::Builder::Action::Command>.

=method flatten

This is an identity operator (it returns C<$self>).
