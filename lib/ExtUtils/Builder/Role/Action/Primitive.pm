package ExtUtils::Builder::Role::Action::Primitive;

use Moo::Role;

with 'ExtUtils::Builder::Role::Action';

sub flatten {
	my $self = shift;
	return $self;
}

1;
