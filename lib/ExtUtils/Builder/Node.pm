package ExtUtils::Builder::Node;

use Moo;

with qw/ExtUtils::Builder::Role::Dependency ExtUtils::Builder::Role::Action::Composite/;

has _actions => (
	is       => 'ro',
	required => 1,
	init_arg => 'actions',
	coerce   => sub {
		return [ map { $_->flatten } @{ $_[0] } ];
	},
);

around flatten => sub {
	my ($orig, $self) = @_;
	return @{ $self->_actions };
};

1;

# ABSTRACT: An ExtUtils::Builder node
