package ExtUtils::Builder::Action::Function;

use Moo;

with 'ExtUtils::Builder::Role::Action::Code';

has [qw/module function/] => (
	is => 'ro',
	required => 1,
);

sub fullname {
	my $self = shift;
	return join '::', $self->module, $self->function;
}

has exports => (
	is => 'ro',
	default => 0,
);

has '+message' => (
	lazy    => 1,
	default => sub {
		my $self => shift;
		return "Calling " . $self->fullname;
	}
);

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
	my $args = %{ $self->arguments } ? ' unshift @_, ' . $self->_get_arguments . ';' : '';
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
