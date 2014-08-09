package ExtUtils::Builder::Action::Code;

use strict;
use warnings FATAL => 'all';

use parent 'ExtUtils::Builder::Role::Action::Code';

use Carp            ();
use Module::Runtime ();

sub new {
	my ($class, %args) = @_;
	Carp::croak('Need to define at least one of code or serialized') if !$args{code} && !$args{serialized};
	my $self = $class->SUPER::new(%args);
	$self->{code} = $args{code} if $args{code};
	$self->{serialized} = $args{serialized} if $args{serialized};
	return $self;
}

my %code_cache;
sub code {
	my $self = shift;
	return $self->{code} ||= do {
		my $self = shift;
		my $code = $self->to_code(skip_loading => 1);
		$code_cache{$code} ||= eval($code) || Carp::croak("Couldn't evaluate serialized: $@");
	};
}

sub serialized {
	my $self = shift;
	return $self->{serialized} ||= do {
		require B::Deparse;
		my $core = B::Deparse->new('-sCi0')->coderef2text($self->{code});
		$core =~ s/ \A { ( .* ) } \z /$1/msx;
		$core =~ s/ \A \n? (.*?) ;? \n? \z /$1/mx;
		$core;
	};
}

sub to_code {
	my ($self, %opts) = @_;
	my @modules = $opts{skip_loading} ? () : map { "require $_; " } $self->modules;
	my $args = $self->_get_arguments('unshift @_, %s; ');
	return join '', 'sub { ', @modules, $args, $self->serialized, ' }';
}

sub _to_call {
	my $self = shift;
	my $serialized = $self->to_code(skip_loading => 1);
	return $serialized =~ /\A sub\ \{ [ ] ([\w:]+) \( \@_ \) [ ] \} \z /x ? $1 : "$serialized->"
}

sub message {
	my $self = shift;
	return $self->{message};
}

1;

#ABSTRACT: Action objects for perl code

=head1 SYNOPSIS

 my $action = ExtUtils::Builder::Action::Code->new(
     code       => \&Frob::nicate,
     serialized => 'Frob::nicate(@_)',
     message    => 'frobnicateing foo',
     arguments  => [ source => 'foo'],
     modules    => ['Frob'],
 );
 $action->execute(target => 'bar');
 say "Executed: ", join ' ', @$_, target => 'bar' for $action->to_command;

=head1 DESCRIPTION

This is a primitive action object wrapping a piece of perl code. The easiest way to use it is to execute it immediately. For more information on using actions, see L<ExtUtils::Builder::Role::Action|ExtUtils::Builder::Role::Action>. The core attributes are code and serialized, though only one of them must be given, both is strongly recommended.

=attr code

This is a code-ref containing the action. On execution, it is passed the arguments of the execute method; when run as command it is passed @ARGV. In either case, C<arguments> is also passed. Of not given, it is C<eval>ed from C<serialized>.

=attr serialized

This is the stringified form of the code of the action. For execution, it's put in a sub with the action's arguments as the subs arguments. If not given, it's decompiled from C<code>.

=method to_code

This returns the code-string for this action.

=begin Pod::Coverage

BUILD

=end Pod::Coverage
