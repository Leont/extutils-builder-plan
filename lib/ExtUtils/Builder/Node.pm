package ExtUtils::Builder::Node;

use strict;
use warnings;

use base qw/ExtUtils::Builder::Action::Composite/;

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

1;

# ABSTRACT: An ExtUtils::Builder Node

=head1 SYNOPSIS

 ExtUtils::Builder::Node->new(
     target       => $target_name,
     dependencies => \@dependencies
     actions      => \@actions,
 );

=head1 DESCRIPTION

A node is the equivalent of a makefile entry. In essence it boils down to its tree attributes. A Node is a L<composite action|ExtUtils::Builder::Action::Composite>, meaning that in can be executed or serialized as a whole, C<actions> contains all associated actions. C<target> and C<dependencies> contain the name of the target and the names of the dependencies.

=attr target

The target filename of this node.

=attr dependencies

The (file)names of the dependencies of this node.

=method flatten

This returns the actions of this node.

=method execute

Execute all actions in this node.

=method to_command

This returns the list commands of all actions in the node.

=method to_code

This returns the list of evaluatable strings of all actions in the node.
