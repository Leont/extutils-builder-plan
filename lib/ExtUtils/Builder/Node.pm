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

sub phony {
	my $self = shift;
	return !!$self->{phony};
}

sub mergeable {
	my $self = shift;
	return $self->{phony} && !@{ $self->{actions} };
}

1;

# ABSTRACT: An ExtUtils::Builder Node

=head1 SYNOPSIS

 ExtUtils::Builder::Node->new(
     target       => $target_name,
     dependencies => \@dependencies
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

=attr phony

If true this node is phony, meaning that it will not produce a file and therefore will be run unconditionally.

=method mergeable

This returns true if a node is mergeable, i.e. it's phony and has no actions.

=begin Pod::Coverage

flatten
execute
to_command
to_code

=end Pod::Coverage
