package ExtUtils::Builder::Role::Action::Code;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Role::Action::Primitive';

use Config;

sub new { 
	my ($class, %args) = @_;
	$args{modules} ||= [];
	$args{arguments} ||= {};
	return $class->SUPER::new(%args);
}

sub _preference_map {
	return {
		execute => 3,
		code    => 2,
		command => 1,
		flatten => 0,
	};
}

sub execute {
	my ($self, %opts) = @_;
	for my $module ($self->modules) {
		(my $filename = "$module.pm") =~ s{::}{/}g;
		require $filename;
	}
	$opts{logger}->($self->message) if $opts{logger} && !$opts{quiet} && exists $self->{message};
	$self->code->(%{ $self->{arguments} }, %opts);
	return;
}

sub _get_arguments {
	my ($self, $format, $default) = @_;
	return $default || '' if !%{ $self->{arguments} };
	require Data::Dumper;
	return sprintf $format, (Data::Dumper->new([ $self->{arguments} ])->Terse(1)->Indent(0)->Dump =~ /^ \{ (.*) \} $/x)[0];
}

sub modules {
	my $self = shift;
	return @{ $self->{modules} };
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
		return $^X if File::Spec->file_name_is_absolute($^X);
		return defined $opts{config} ? $opts{config}->get('perlpath') : $Config{perlpath};
	}
}

sub to_command {
	my ($self, %opts) = @_;
	my @modules = map { "-M$_" } $self->modules;
	my $args = $self->_get_arguments('%s, @ARGV', '@ARGV');
	return [ _get_perl(%opts), @modules, '-e', $self->_to_call() . "($args)" ];
}

1;

# ABSTRACT: A base-role for Code actions

=head1 DESCRIPTION

This role provides most functionality of Code Actions.

=attr arguments

These are additional arguments to the action, that are passed on regardless of how the action is run. This attribute is optional.

=attr modules

This is an optional list of modules that will be dynamically loaded before the action is run in any way. This attribute is optional.

=attr message

This is a message that will be logged during execution. This attribute is optional.

=method execute

This executes the command immediately.

=method to_command

This returns an arrayref containing a command for this action.

=method preference

This will prefer handling methods in the following order: execute, code, command, flatten

=method code

…
