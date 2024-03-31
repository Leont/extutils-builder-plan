package ExtUtils::Builder::Action::Perl;

use strict;
use warnings;

use base 'ExtUtils::Builder::Action::Primitive';

use Config;
use Scalar::Util 'tainted';

sub _preference_map {
	return {
		execute => 3,
		code    => 2,
		command => 1,
		flatten => 0,
	};
}

sub modules {
	my $self = shift;
	return @{ $self->{modules} };
}

sub message {
	my $self = shift;
	return $self->{message};
}

sub _get_perl {
	my %opts = @_;
	return $opts{perl} if $opts{perl};
	if ($Config{userelocatableinc}) {
		require Devel::FindPerl;
		return Devel::FindPerl::find_perl_interpreter($opts{config});
	}
	else {
		require File::Spec;
		return $^X if File::Spec->file_name_is_absolute($^X) and not tainted($^X);
		return defined $opts{config} ? $opts{config}->get('perlpath') : $Config{perlpath};
	}
}

sub to_command {
	my ($self, %opts) = @_;
	my @modules = map { "-M$_" } $self->modules;
	return [ _get_perl(%opts), @modules, '-e', $self->to_code(skip_loading => 'main') ];
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
