package ExtUtils::Builder::Action::Code;

use Moo;

with 'ExtUtils::Builder::Role::Action::Primitive';

use Carp            ();
use Module::Runtime ();

sub _preference_map {
	return {
		execute => 3,
		code    => 2,
		command => 1,
		flatten => 0,
	};
}

my %code_cache;
has code => (
	is        => 'lazy',
	predicate => '_has_code',
	default   => sub {
		my $self = shift;
		my $code = $self->to_code(skip_loading => 1);
		return $code_cache{$code} ||= eval($code) || Carp::croak("Couldn't evaluate serialized: $@");
	},
);

has message => (
	is        => 'ro',
	predicate => '_has_message',
);

sub execute {
	my ($self, %opts) = @_;
	Module::Runtime::require_module($_) for @{ $self->_modules };
	$opts{logger}->($self->message) if $opts{logger} && !$opts{quiet} && $self->_has_message;
	$self->code->(%{ $self->arguments }, %opts);
	return;
}

has serialized => (
	is        => 'lazy',
	predicate => '_has_serialized',
	default   => sub {
		my $self = shift;

		require B::Deparse;
		my $core = B::Deparse->new('-sCi0')->coderef2text($self->code);
		$core =~ s/ \A { ( .* ) } \z /$1/msx;
		$core =~ s/ \A \n? (.*?) ;? \n? \z /$1/mx;
		return $core;
	},
);

sub BUILD {
	my $self = shift;
	Carp::croak('Need to define at least one of code or serialized') if !$self->_has_code && !$self->_has_serialized;
	return;
}

sub to_code {
	my ($self, %opts) = @_;
	my @modules = $opts{skip_loading} ? () : map { "require $_; " } @{ $self->_modules };
	my $args = %{ $self->arguments } ? 'unshift @_, ' . $self->_get_arguments . ';' : '';
	return join '', 'sub { ', @modules, $args, $self->serialized, ' }';
}

has arguments => (
	is      => 'ro',
	default => sub { {} },
);

has _modules => (
	is       => 'ro',
	init_arg => 'modules',
	default  => sub { [] },
);

sub _get_perl {
	my %opts = @_;
	return $opts{perl} if $opts{perl};
	require Devel::FindPerl;
	return Devel::FindPerl::find_perl_interpreter($opts{config});
}

sub _get_arguments {
	my $self = shift;
	return if not %{ $self->arguments };
	require Data::Dumper;
	return (Data::Dumper->new([ $self->arguments ])->Terse(1)->Indent(0)->Dump =~ /^ \{ (.*) \} $/x)[0];
}

sub to_command {
	my ($self, %opts) = @_;
	my $serialized = $self->to_code(skip_loading => 1);
	my $args = join ', ', $self->_get_arguments, '@ARGV';
	my $perl = _get_perl(%opts);
	my @modules = map { "-M$_" } @{ $self->_modules };
	return [ $perl, @modules, '-e', "($serialized)->($args)" ];
}

1;

#ABSTRACT: An action object for perl code

=head1 SYNOPSIS

 my $action = ExtUtils::Builder::Action::Code->new(
     code       => sub { Frob::nicate(@_) },
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

=attr arguments

These are additional arguments to the action, that are passed on regardless of how the action is run. This attribute is optional.

=attr modules

This is an optional list of modules that will be dynamically loaded before the action is run in any way. This attribute is optional.

=attr message

This is a message that will be logged during execution. This attribute is optional.

=method execute

This executes the command immediately.

=method to_code

This returns the code-string for this action.

=method to_command

This returns an arrayref containing a command for this action.

=method preference

This will prefer handling methods in the following order: execute, code, command, flatten

=method flatten

This returns the object.

=begin Pod::Coverage

BUILD

=end Pod::Coverage
