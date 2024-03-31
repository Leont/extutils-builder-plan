package ExtUtils::Builder::Action::Command;

use strict;
use warnings;

use base 'ExtUtils::Builder::Action::Primitive';

sub _preference_map {
	return {
		command => 3,
		execute => 2,
		code    => 1,
		flatten => 0,
	};
}

sub to_code {
	my ($self, %args) = @_;
	require Data::Dumper;
	my $serialized = Data::Dumper->new([$self->{command}])->Terse(1)->Indent(0)->Dump;
	$serialized =~ s/ \A \[ (.*?) \] \z /$1/xms;
	return qq{system($serialized) and die "Could not run command " . join ' ', $serialized};
}

sub to_command {
	my $self = shift;
	return [ @{ $self->{command} } ];
}

my $quote = $^O eq 'MSWin32' ? do { require Win32::ShellQuote; \&Win32::ShellQuote::quote_system_list } : sub { @_ };
sub execute {
	my ($self, %opts) = @_;
	my @command = @{ $self->{command} };
	my $message = join ' ', map { my $arg = $_; $arg =~ s/ (?= ['#] ) /\\/gx ? "'$arg'" : $arg } @command;
	$opts{logger}->($message) if $opts{logger} and not $opts{quiet};
	system($quote->(@command)) and die "Could not run command @command" if not $opts{dry_run};
	return;
}

1;

#ABSTRACT: An action object for external commands

=head1 SYNOPSIS

 my @cmd = qw/echo Hello World!/;
 my $action = ExtUtils::Builder::Action::Command->new(command => \@cmd);
 $action->execute;
 say "Executed: ", join ' ', @{$_} for $action->to_command;

=head1 DESCRIPTION

This is a primitive action object wrapping an external command. The easiest way to use it is to serialize it to command, though it doesn't mind being executed right away. For more information on actions, see L<ExtUtils::Builder::Action|ExtUtils::Builder::Action>.

=attr command

This is the command that should be run, represented as an array ref.

=begin Pod::Coverage

execute
to_command
to_code
preference
flatten

=end Pod::Coverage
