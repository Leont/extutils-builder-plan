package ExtUtils::Builder::Role::Action::Code;

use Moo::Role;

with 'ExtUtils::Builder::Role::Action::Primitive';

requires qw/_to_call code/;

sub _preference_map {
	return {
		execute => 3,
		code    => 2,
		command => 1,
		flatten => 0,
	};
}

has message => (
	is        => 'ro',
	predicate => '_has_message',
);

sub execute {
	my ($self, %opts) = @_;
	Module::Runtime::require_module($_) for $self->modules;
	$opts{logger}->($self->message) if $opts{logger} && !$opts{quiet} && $self->_has_message;
	$self->code->(%{ $self->arguments }, %opts);
	return;
}

has arguments => (
	is      => 'ro',
	default => sub { {} },
);

sub _get_arguments {
	my $self = shift;
	return if not %{ $self->arguments };
	require Data::Dumper;
	return (Data::Dumper->new([ $self->arguments ])->Terse(1)->Indent(0)->Dump =~ /^ \{ (.*) \} $/x)[0];
}

has _modules => (
	is       => 'ro',
	init_arg => 'modules',
	default  => sub { [] },
);

sub modules {
	my $self = shift;
	return @{ $self->_modules };
}

sub _get_perl {
	my %opts = @_;
	return $opts{perl} if $opts{perl};
	require Devel::FindPerl;
	return Devel::FindPerl::find_perl_interpreter($opts{config});
}

sub to_command {
	my ($self, %opts) = @_;
	my @modules = map { "-M$_" } $self->modules;
	my $args = join(', ', $self->_get_arguments, '@ARGV');
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
