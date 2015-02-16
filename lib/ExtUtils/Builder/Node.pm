package ExtUtils::Builder::Node;

use strict;
use warnings FATAL => 'all';

use parent qw/ExtUtils::Builder::Role::Action::Composite ExtUtils::Builder::Role::Dependency/;

use Carp 'croak';

sub new {
	my ($class, %args) = @_;
	croak('Attribute actions is not defined') if not $args{actions};
	$args{actions} = [ map { $_->flatten } @{ $args{actions} } ];
	return $class->SUPER::new(%args);
}

sub flatten {
	my $self = shift;
	return @{ $self->{actions} };
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

A node is the equivalent of a makefile entry. In essence it boils down to its tree attributes. C<target> and C<dependencies> are composed from L<ExtUtils::Builder::Role::Dependency|ExtUtils::Builder::Role::Dependency>, and C<actions> contains all associated actions. A Node is a L<composite action|ExtUtils::Builder::Role::Action::Composite>, meaning that in can be executed or serialized as a whole. Flattening is recommended before complex serializations. See L<ExtUtils::Builder::Role::Action|ExtUtils::Builder::Role::Action> for more details.

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
