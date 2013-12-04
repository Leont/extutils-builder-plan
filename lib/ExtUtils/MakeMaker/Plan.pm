package ExtUtils::MakeMaker::Plan;

use strict;
use warnings FATAL => 'all';

sub escape_command {
	my ($maker, $elements) = @_;
	return join ' ', map { (my $temp = m{[^\w/\$().-]} ? $maker->quote_literal($_) : $_) =~ s/\n/\\\n\t/g; $temp } @{$elements};
}

sub make_entry {
	my ($maker, $node) = @_;
	my @commands = map { escape_command($maker, $_) } $node->to_command(perl => '$(ABSPERLRUN)');
	return join "\n\t", $node->target . ' : ' . join(' ', $node->dependencies), @commands;
}

sub MY::postamble {
	my ($self, %args) = @_;
	my @glue = 'pure_all :: ' . join ' ', @{ $args{roots} || [] };
	my @plans = map { make_entry($self, $_) } @{ $args{plans} || [] };
	return join "\n\n", @glue, @plans;
}

1;
