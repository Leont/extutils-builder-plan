package ExtUtils::Builder::FileSet::Free;

use strict;
use warnings;

use base 'ExtUtils::Builder::FileSet';

sub add_input {
	my ($self, $entry) = @_;
	$self->_pass_on($entry);
	return $entry;
}

1;
