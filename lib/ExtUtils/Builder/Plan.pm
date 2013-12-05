package ExtUtils::Builder::Plan;

use Moo;
use Carp ();

with 'ExtUtils::Builder::Role::Action::Composite';

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

sub _node_sorter {
	my ($self, $name, $callback, $seen, $loop) = @_;
	Carp::croak("$name has a circular dependency, aborting!\n") if exists $loop->{$name};
	return if $seen->{$name}++;
	my $node = $self->_nodes->{$name} or Carp::confess("Node $name doesn't exist");
	local $loop->{$name} = 1;
	$self->_node_sorter($_, $callback, $seen, $loop) for $node->dependencies;
	$callback->($name, $node);
	return;
}

around execute => sub {
	my ($orig, $self, %options) = @_;
	my @seenloop = ({}, {});
	my $run_node = sub {
		my ($name, $node) = @_;
		return if -e $name and sub { -d $_ or -M $name <= -M $_ or return 0 for sort $node->dependencies; 1 }->();
		$node->execute(%options);
	};
	$self->_node_sorter($_, $run_node, @seenloop) for $self->roots;
	return;
};

around flatten => sub {
	my ($orig, $self) = @_;
	my @ret;
	my @seenloop = ({}, {});
	$self->_node_sorter($_, sub { push @ret, $_[1]->flatten }, @seenloop) for $self->roots;
	return @ret;
};

1;

# ABSTRACT: An ExtUtils::Builder plan
