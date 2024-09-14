package ExtUtils::Builder::Action::Function;

use strict;
use warnings;

use Carp 'croak';
use ExtUtils::Builder::Util 'get_perl';

use parent 'ExtUtils::Builder::Action::Perl';

sub new {
	my ($class, %args) = @_;
	croak 'Attribute module is not defined' if not defined $args{module};
	croak 'Attribute function is not defined' if not defined $args{function};
	$args{fullname} = join '::', $args{module}, $args{function};
	$args{exports} ||= !!0;
	$args{arguments} //= [];
	my $self = $class->SUPER::new(%args);
	return $self;
}

sub modules {
	my ($self) = @_;
	return $self->{module};
}

sub module {
	my ($self) = @_;
	return $self->{module};
}

sub function {
	my ($self) = @_;
	return $self->{function};
}

sub arguments {
	my ($self) = @_;
	return @{ $self->{arguments} };
}

sub execute {
	my ($self, %args) = @_;
	my $module = $self->{module};
	(my $filename = $module) =~ s{::}{/}g;
	require "$filename.pm";

	if (!$args{quiet}) {
		my $message = $self->{message} // sprintf "%s(%s)", $self->{fullname}, join ", ", $self->arguments;
		print "$message\n";
	}

	my $code = do { no strict 'refs'; \&{ $self->{fullname} } };
	$code->($self->arguments);
}

sub to_code {
	my ($self, %args) = @_;
	my $shortcut = $args{skip_loading} && $args{skip_loading} eq 'main' && $self->{exports};
	my $name = $shortcut ? $self->{function} : $self->{fullname};
	my @modules = $args{skip_loading} ? () : "require $self->{module}";
	my $arguments = $self->arguments ? do {
		require Data::Dumper; (Data::Dumper->new([ [ $self->arguments ] ])->Terse(1)->Indent(0)->Dump =~ /^ \[ (.*) \] $/x)[0]
	} : '';
	return join '; ', @modules, sprintf '%s(%s)', $name, $arguments;
}

sub to_command {
	my ($self, %opts) = @_;
	my $module = $self->{exports} eq 'explicit' ? "-M$self->{module}=$self->{function}" : "-M$self->{module}";
	return [ get_perl(%opts), $module, '-e', $self->to_code(skip_loading => 'main') ];
}

1;

#ABSTRACT: Actions for perl function calls

=head1 SYNOPSIS

 my $action = ExtUtils::Builder::Action::Function->new(
     module    => 'Frob',
     function  => 'nicate',
     arguments => [ target => 'bar' ],
 );
 $action->execute();
 say "Executed: ", join ' ', @$_, target => 'bar' for $action->to_command;

=head1 DESCRIPTION

This Action class is a specialization of L<Action::Perl|ExtUtils::Builder::Action::Perl> that makes the common case of calling a simple function easier. The first statement in the synopsis is roughly equivalent to:

 my $action = ExtUtils::Builder::Action::Code->new(
     code       => 'Frob::nicate(target => 'bar')',
     module     => ['Frob'],
     message    => 'Calling Frob::nicate',
 );

Except that it serializes more cleanly.

=attr arguments

These are additional arguments to the action, that are passed on regardless of how the action is run. This attribute is optional.

=attr module

The module to be loaded.

=attr function

The name of the function to be called.

=attr exports 

If C<"always">, the function is assumed to be exported by the module. If C<"explicit">, it's assumed to need explicit exporting (e.g. C<use Module 'function';>).

=begin Pod::Coverage

to_code

=end Pod::Coverage
