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
