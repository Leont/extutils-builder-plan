package ExtUtils::Builder::Plan;

use Moo;

has _nodes => (
	is => 'ro',
	init_arg => 'nodes',
	default => sub { [] },
	coerce => sub {
		return +{ map { $_->target => $_ } @{ $_[0] } };
	}
);

sub nodes {
	my $self = shift;
	return values %{ $self->_nodes };
}

has _roots => (
	is => 'ro',
	init_arg => 'roots',
	required => 1,
	coerce => sub {
		return ref($_[0]) eq 'ARRAY' ? $_[0] : [ $_[0] ];
	}
);

sub roots {
	my $self = shift;
	return @{ $self->_roots };
}

1;

# ABSTRACT: An ExtUtils::Builder plan
