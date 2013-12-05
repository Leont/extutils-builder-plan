package ExtUtils::Builder::Action::Command;

use Moo;

with 'ExtUtils::Builder::Role::Action::Primitive';

use IPC::System::Simple qw/systemx/;

sub _preference_map {
	return {
		command => 3,
		execute => 2,
		code    => 1,
		flatten => 0,
	};
}

has _command => (
	is       => 'ro',
	required => 1,
	init_arg => 'command',
);

sub to_code {
	my $self = shift;
	require Data::Dumper;
	my $serialized = Data::Dumper->new([ $self->to_command ])->Terse(1)->Indent(0)->Dump;
	return "sub { require IPC::System::Simple; IPC::System::Simple::systemx($serialized);";
}

sub to_command {
	my $self = shift;
	return [ @{ $self->_command } ];
}

sub execute {
	my ($self, %opts) = @_;
	my @command = @{ $self->to_command };
	my $message = join ' ', map { my $arg = $_; $arg =~ s/ (?= ['#] ) /\\/gx ? "'$arg'" : $arg } @command;
	$opts{logger}->($message) if $opts{logger} and not $opts{quiet};
	systemx(@command) if not $opts{dry_run};
	return;
}

1;
