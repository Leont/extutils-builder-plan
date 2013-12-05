package ExtUtils::Builder::Role::Action::Composite;

use Moo::Role;

with 'ExtUtils::Builder::Role::Action';

sub _preference_map {
	return {
		flatten => 3,
		execute => 2,
		command => 1,
		code    => 0,
	};
}

sub execute {
	my ($self, %opts) = @_;
	$_->execute(%opts) for $self->flatten;
	return;
}

sub to_code {
	my ($self, %opts) = @_;
	return map { $_->to_code(%opts) } $self->flatten;
}

sub to_command {
	my ($self, %opts) = @_;
	return map { $_->to_command(%opts) } $self->flatten;
}

1;
