package ExtUtils::MakeMaker::Plan;

use strict;
use warnings FATAL => 'all';

sub escape_command {
	my ($maker, $elements) = @_;
	return join ' ', map { (my $temp = m{[^\w/\$().-]} ? $maker->quote_literal($_) : $_) =~ s/\n/\\\n\t/g; $temp } @{$elements};
}

sub make_entry {
	my ($maker, $plan) = @_;
	my @commands = map { escape_command($maker, $_) } $plan->to_command(perl => '$(ABSPERLRUN)');
	return join "\n\t", $plan->target . ' : ' . join(' ', $plan->dependencies), @commands;
}

sub MY::postamble {
	my ($self, %args) = @_;
	return join "\n\n", map { make_entry($self, $_) } @{ $args{plans} || [] };
}

1;
