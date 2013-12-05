package ExtUtils::Builder::Role::Action;

use Moo::Role;

requires qw/_preference_map execute to_code to_command flatten/;

sub preference {
	my ($self, @possibilities) = @_;
	my $map = $self->_preference_map;
	my @keys = @possibilities ? @possibilities : keys %{$map};
	my ($ret) = reverse sort { $map->{$a} <=> $map->{$b} } @keys;
	return $ret;
}

1;
