package ExtUtils::Builder::Util;

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/get_perl/;

use Config;
use ExtUtils::Config;
use File::Spec::Functions 'file_name_is_absolute';
use Scalar::Util 'tainted';

sub get_perl {
	my (%opts) = @_;
	return $opts{perl} if $opts{perl};
	my $config = $opts{config} || ExtUtils::Config->new;
	if ($config->get('userelocatableinc')) {
		require Devel::FindPerl;
		return Devel::FindPerl::find_perl_interpreter($config);
	}
	else {
		require File::Spec;
		return $^X if file_name_is_absolute($^X) and not tainted($^X);
		return $opts{config}->get('perlpath');
	}
}

sub require_module {
	my $module = shift;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	return $module;
}

1;

# ABSTRACT: Utility functions for ExtUtils::Builder

=head1 DESCRIPTION

This is a module containing some helper functions for L<ExtUtils::Builder>.

=func get_perl(%options)

This function takes a hash with various (optional) keys:

=over 4

=item * perl

The location of the perl executable

=item * config

An L<ExtUtils::Config|ExtUtils::Config> (compatible) object.

=back

=func require_module($module)

Dynamically require a module.
