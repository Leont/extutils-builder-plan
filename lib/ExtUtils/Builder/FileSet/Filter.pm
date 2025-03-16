package ExtUtils::Builder::FileSet::Filter;

use strict;
use warnings;

use base 'ExtUtils::Builder::FileSet';

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{condition} = $args{condition} or Carp::croak('No condition given');
	return $self;
}

sub add_input {
	my ($self, $source) = @_;

	if ($self->{condition}->($source)) {
		$self->_pass_on($source);
	}
	return $source;
}

1;
