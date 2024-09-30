package ExtUtils::Builder::Util;

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/get_perl require_module command code function/;

use Config;
use ExtUtils::Config;
use File::Spec::Functions 'file_name_is_absolute';
use Scalar::Util 'tainted';

sub get_perl {
	my (%opts) = @_;
	my $config = $opts{config} // ExtUtils::Config->new;

	if (file_name_is_absolute($^X) and not tainted($^X)) {
		return $^X;
	}
	elsif ($config->get('userelocatableinc')) {
		require Devel::FindPerl;
		return Devel::FindPerl::find_perl_interpreter($config);
	}
	else {
		return $opts{config}->get('perlpath');
	}
}

sub require_module {
	my $module = shift;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	return $module;
}

sub command {
	my (@command) = @_;
	require ExtUtils::Builder::Action::Command;
	return ExtUtils::Builder::Action::Command->new(command => \@command);
}

sub code {
	my %args = @_;
	require ExtUtils::Builder::Action::Code;
	return ExtUtils::Builder::Action::Code->new(%args);
}

sub function {
	my %args = @_;
	require ExtUtils::Builder::Action::Function;
	return ExtUtils::Builder::Action::Function->new(%args);
}

1;

# ABSTRACT: Utility functions for ExtUtils::Builder

=head1 DESCRIPTION

This is a module containing some helper functions for L<ExtUtils::Builder>.

=func function(%arguments)

This is a shorthand for calling L<ExtUtils::Builder::Action::Function|ExtUtils::Builder::Action::Function>'s contructor.

=func command(%arguments)

This is a shorthand for calling L<ExtUtils::Builder::Action::Code|ExtUtils::Builder::Action::Code>'s contructor.

=func code(@command)

This is a shorthand for calling L<ExtUtils::Builder::Action::Code|ExtUtils::Builder::Action::Code>'s contructor, with C<@command> passed as its C<command> argument.

=func get_perl(%options)

This function takes a hash with various (optional) keys:

=over 4

=item * config

An L<ExtUtils::Config|ExtUtils::Config> (compatible) object.

=back

=func require_module($module)

Dynamically require a module.
