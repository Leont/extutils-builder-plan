package ExtUtils::Builder::Action::Function;

use strict;
use warnings;
use Carp 'croak';

use parent 'ExtUtils::Builder::Role::Action::Code';

sub new {
	my ($class, %args) = @_;
	croak 'Attribute module is not defined' if not defined $args{module};
	croak 'Attribute function is not defined' if not defined $args{function};
	$args{exports} ||= 0;
	my $self = $class->SUPER::new(%args);
	return $self;
}

for my $attr (qw/module function exports/) {
	my $method = sub {
		my $self = shift;
		return $self->{$attr};
	};
	no strict 'refs';
	*{$attr} = $method;
}

sub fullname {
	my $self = shift;
	return join '::', $self->module, $self->function;
}

sub message {
	my $self = shift;
	return $self->{message} ||= 'Calling ' . $self->fullname;
}

sub code {
	my $self = shift;
	no strict 'refs';
	return \&{ $self->fullname };
}

sub _to_call {
	my $self = shift;
	return $self->exports ? $self->function : $self->fullname;
}

sub to_code {
	my $self = shift;
	my ($module, $fullname) = ($self->module, $self->fullname);
	my $args =  $self->_get_arguments(' unshift @_, %s;');
	return "sub { require $module;$args $fullname(\@_) }";
}

1;

#ABSTRACT: Actions for perl function calls

=head1 SYNOPSIS

 my $action = ExtUtils::Builder::Action::Function->new(
     module    => 'Frob',
     function  => 'nicate',
 );
 $action->execute(target => 'bar');
 say "Executed: ", join ' ', @$_, target => 'bar' for $action->to_command;

=head1 DESCRIPTION

This Action class is a specialization of L<Action::Code|ExtUtils::Builder::Action::Code> that makes the common case of calling a simple function easier. The first statement in the synopsis is roughly equivalent to:

 my $action = ExtUtils::Builder::Action::Code->new(
     code       => \&Frob::nicate,
     serialized => 'Frob::nicate(@_)',
     message    => 'Calling Frob::nicate',
     modules    => ['Frob'],
 );

Except that is serializes more cleanly.

=attr module

=attr function

=attr exports 

=method to_code

=begin Pod::Coverage

BUILDARGS
code
fullname

=end Pod::Coverage
