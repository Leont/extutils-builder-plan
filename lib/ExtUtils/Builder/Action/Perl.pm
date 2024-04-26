package ExtUtils::Builder::Action::Perl;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Action::Primitive';

sub _preference_map {
	return {
		execute => 3,
		code    => 2,
		command => 1,
		flatten => 0,
	};
}

sub message {
	my $self = shift;
	return $self->{message};
}

sub to_code_hash {
	my ($self, %opts) = @_;
	my %result = (
		modules => [ $self->modules ],
		code    => $self->to_code(skip_loading => 1, %opts),
	);
	$result{message} = $self->{message} if defined $self->{message};
	return \%result;
}

1;

# ABSTRACT: A base-role for Code actions

=head1 DESCRIPTION

This class provides most functionality of Code Actions.

=attr message

This is a message that will be logged during execution. This attribute is optional.

=method modules

This will return the modules needed for this action.

=begin Pod::Coverage

execute
to_command
preference

=end Pod::Coverage
