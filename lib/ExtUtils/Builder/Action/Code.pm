package ExtUtils::Builder::Action::Code;

use strict;
use warnings;

use base 'ExtUtils::Builder::Role::Action::Code';

use Carp ();

sub new {
	my ($class, %args) = @_;
	Carp::croak('Need to define code') if !$args{code};
	$args{modules} ||= [];
	my $self = $class->SUPER::new(%args);
	return $self;
}

sub to_code {
	my ($self, %opts) = @_;
	my @modules = $opts{skip_loading} ? () : map { "require $_" } $self->modules;
	return join '; ', @modules, $self->{code};
}

1;

#ABSTRACT: Action objects for perl code

=head1 SYNOPSIS

 my $action = ExtUtils::Builder::Action::Code->new(
     code      => 'Frob::nicate(@_)',
     modules    => ['Frob'],
     message   => 'frobnicateing foo',
 );
 $action->execute(target => 'bar');
 say "Executed: ", join ' ', @$_, target => 'bar' for $action->to_command;

=head1 DESCRIPTION

This is a primitive action object wrapping a piece of perl code. The easiest way to use it is to execute it immediately. For more information on using actions, see L<ExtUtils::Builder::Role::Action|ExtUtils::Builder::Role::Action>. The core attributes are code and serialized, though only one of them must be given, both is strongly recommended.

=attr code

This is a code-ref containing the action. On execution, it is passed the arguments of the execute method; when run as command it is passed @ARGV. In either case, C<arguments> is also passed. Of not given, it is C<eval>ed from C<serialized>.

=attr modules

This is an optional list of modules that will be dynamically loaded before the action is run in any way. This attribute is optional.

=method to_code

This returns the code-string for this action.

=begin Pod::Coverage

BUILD

=end Pod::Coverage
