package ExtUtils::Builder::MakeMaker::Config;

use strict;
use warnings;

use ExtUtils::MakeMaker::Config;

sub new {
    my ($class, $maker) = @_;
    return bless { maker => $maker }, $class;
}

sub get {
    my ($self, $key) = @_;
    return exists $self->{maker}{uc $key} ? $self->{maker}{uc $key} : $Config{$key};
}

sub exists {
    my ($self, $key) = @_;
	return exists $Config{$key};
}

sub all_config {
	my $self = shift;
	my %result;
	for my $key (keys %Config) {
		$result{$key} = $self->get($key);
	}
	return \%result;
}

sub values_set {
	my $self = shift;
	my %result;
	for my $key (keys %Config) {
		next if not exists $self->{maker}{uc $key};
		next if $self->{maker}{uc $key} eq $Config{$key};
		$result{$key} = $self->{maker}{uc $key};
	}
	return \%result;
}

sub serialize {
	my $self = shift;
	require Data::Dumper;
	return $self->{serialized} ||= Data::Dumper->new($self->values_set)->Terse(1)->Sortkeys(1)->Dump;
}

1;

#ABSTRACT: A ExtUtils::Config compatible wrapper for ExtUtils::MakeMaker's configuration.

=head1 SYNOPSIS

 sub MY::postamble {
   my ($self, $args) = @_;
   my $config = ExtUtils::Builder::MakeMaker::Config->new($self);
   my $plan = make_plan('src', $config);
   return $self->SUPER::postamble(plans => [ $plan ]);
 }

=head1 DESCRIPTION

This object wraps L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>'s idea of configuration in an L<ExtUtils::Config|ExtUtils::Config> compatible interface.

=method new($makemaker)

This creates a new C<ExtUtils::Builder::MakeMaker::Config> object from a MakeMaker object.

=method get($key)

Get the value of C<$key>. If not overridden it will return the value in %Config.

=method exists($key)

Tests for the existence of $key.

=method values_set()

Get a hashref of all overridden values.

=method all_config()

Get a hashref of the complete configuration, including overrides.

=method serialize()

This method serializes the object to some kind of string. This can be useful for various caching purposes.
