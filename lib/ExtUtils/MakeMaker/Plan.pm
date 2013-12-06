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
	my @plans = ref $args{plans} eq 'ARRAY' ? @{ $args{plans} } : defined $args{plans} ? $args{plans} : ();
	my @glue = 'pure_all :: ' . join ' ', map { $_->roots } @plans;
	my @entries = map { make_entry($self, $_) } map { $_->nodes } @plans;
	return join "\n\n", @glue, @entries;
}

1;

#ABSTRACT: A MakeMaker consumer for ExtUtils::Builder Plan objects

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 use ExtUtils::MakeMaker::Plan;
 ...
 my @plans = Frobnicator->new->plans;
 WriteMakeFile(
   NAME => 'Foo',
   VERSION => 0.001,
   postamble => {
     plans => \@plans,
   }
 );

=head1 DESCRIPTION

This MakeMaker extension consumes ExtUtils::Builder::Plan objects, converting them into the Makefile. It only requires you to:

=over 4

=item * Load this module along with MakeMaker.

=item * Pass on the plans using the postamble.plans argument of WriteMakefile.

=back

=method make_entry($makemaker, $node)

This takes a L<Node|ExtUtils::Builder::Node> object and turns it into a makefile entry.

=method escape_command($makemaker, $elements)

Escape a command for inclusion in a makefile line. C<$elements> is an array-ref containing the elements of the command (e.g. C<['echo', 'Hello', 'World!']>).

=head1 COMPATIBILITY

This MakeMaker extension may be uncompatible with other postamble extensions. YMMV.
