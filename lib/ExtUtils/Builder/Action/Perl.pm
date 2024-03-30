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

sub execute {
	my ($self, %opts) = @_;
	my $code = $self->to_code();
	if ($opts{logger} && !$opts{quiet}) {
		my $message = $self->{message} || $code;
		$opts{logger}->($message);
	}
	eval $code . '; 1' or die $@;
	return;
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

1;

# ABSTRACT: A base-role for Code actions

=head1 DESCRIPTION

This class provides most functionality of Code Actions.

=attr message

This is a message that will be logged during execution. This attribute is optional.

=method execute(%opts)

This executes the command immediately.

=method to_command(%opts)

This returns an arrayref containing a command for this action.

=method preference

This will prefer handling methods in the following order: execute, code, command, flatten

=method modules

This will return the modules needed for this action.
