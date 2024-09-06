package ExtUtils::Builder::Node;

use strict;
use warnings;

use parent qw/ExtUtils::Builder::Action::Composite/;

use Carp 'croak';

sub new {
	my ($class, %args) = @_;
	croak('Attribute target is not defined') if not $args{target};
	$args{actions} = [ map { $_->flatten } @{ $args{actions} || [] } ];
	$args{dependencies} ||= [];
	$args{type} ||= delete $args{phony} ? 'phony' : 'file';
	return $class->SUPER::new(%args);
}

sub flatten {
	my $self = shift;
	return @{ $self->{actions} };
}

sub target {
	my $self = shift;
	return $self->{target};
}

sub dependencies {
	my $self = shift;
	return @{ $self->{dependencies} };
}

sub type {
	my $self = shift;
	return $self->{type};
}

sub phony {
	my $self = shift;
	return $self->{type} eq 'phony';
}

sub mergeable {
	my $self = shift;
	return $self->{type} eq 'phony' && !@{ $self->{actions} };
}

sub newer_than {
	my ($self, $mtime) = @_;
	return 1 if $self->{type} eq 'phony';
	return -d $self->{target} || (-e _ && $mtime <= -M _);
}

1;

# ABSTRACT: An ExtUtils::Builder Node

=head1 SYNOPSIS

 ExtUtils::Builder::Node->new(
     target       => $target_name,
     dependencies => \@dependencies,
     actions      => \@actions,
 );

=head1 DESCRIPTION

A node is the equivalent of a makefile entry. In essence it boils down to its three attributes: C<target> (the name of the target), C<dependencies>(the names of the dependencies) and C<actions>. A Node is a L<composite action|ExtUtils::Builder::Action::Composite>, meaning that in can be executed or serialized as a whole.

=attr target

The target filename of this node.

=attr dependencies

The (file)names of the dependencies of this node.

=attr actions

A list of L<actions|ExtUtils::Builder::Action> for this node.

=attr type

This must be one of C<file> or C<phony>. In the latter case the target will not be represented on the filesystem.

=attr phony

B<Deprecated>.

Instead, pass C<< type => 'phony' >>

=method mergeable

This returns true if a node is mergeable, i.e. it's phony and has no actions.

=begin Pod::Coverage

flatten
execute
to_command
to_code
newer_than

=end Pod::Coverage
