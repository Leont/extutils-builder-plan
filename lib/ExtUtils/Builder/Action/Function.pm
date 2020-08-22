package ExtUtils::Builder::Action::Function;

use strict;
use warnings;
use Carp 'croak';

use base 'ExtUtils::Builder::Role::Action::Perl';

sub new {
	my ($class, %args) = @_;
	croak 'Attribute module is not defined' if not defined $args{module};
	croak 'Attribute function is not defined' if not defined $args{function};
	$args{fullname} = join '::', $args{module}, $args{function};
	$args{exports} ||= 0;
	$args{message} ||= "Calling $args{fullname}";
	$args{arguments} ||= [];
	$args{modules} = [ $args{module} ];
	my $self = $class->SUPER::new(%args);
	return $self;
}

sub execute {
	my ($self, %args) = @_;
	(my $filename = "$self->{module}.pm") =~ s{::}{/}g;
	require $filename;

	my $code = do { no strict 'refs'; \&{ $self->{fullname} } };
	$code->(@{ $self->{arguments} });
}

sub to_code {
	my ($self, %args) = @_;
	my $skip_loading = $args{skip_loading} || '';
	my $shortcut = $args{skip_loading} && $args{skip_loading} eq 'main' && $self->{exports};
	my $name = $shortcut ? $self->{function} : $self->{fullname};
	my @modules = $opts{skip_loading} ? () : map { "require $_" } $self->modules;
	my $arguments = @{ $self->{arguments} } ? do {
		require Data::Dumper; (Data::Dumper->new([ $args{arguments} ])->Terse(1)->Indent(0)->Dump =~ /^ \[ (.*) \] $/x)[0]
	} : '';
	return join '; ', @modules, sprintf '%s(%s)', $name, $arguments;
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

This Action class is a specialization of L<Action::Code|ExtUtils::Builder::Action::Code> that makes the common case of calling a simple function easier. The first statement in the synopsis is roughly equivalent to:

 my $action = ExtUtils::Builder::Action::Code->new(
     code       => 'Frob::nicate(target => 'bar')',
     modules    => ['Frob'],
     message    => 'Calling Frob::nicate',
 );

Except that is serializes more cleanly.

=attr arguments

These are additional arguments to the action, that are passed on regardless of how the action is run. This attribute is optional.

=attr module

=attr function

=attr exports 

=method to_code

=begin Pod::Coverage

BUILDARGS
code
fullname

=end Pod::Coverage
