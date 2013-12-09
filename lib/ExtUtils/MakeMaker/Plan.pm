package ExtUtils::MakeMaker::Plan;

use strict;
use warnings FATAL => 'all';

use Exporter;
our @EXPORT_OK = qw/postamble make_entry escape_command/;

sub import {
	my ($class, @args) = @_;
	if (@args == 1 and $args[0] eq '-global') {
		*MY::postamble = \&postamble;
	}
	else {
		goto &Exporter::import;
	}
}

sub escape_command {
	my ($maker, $elements) = @_;
	return join ' ', map { (my $temp = m{[^\w/\$().-]} ? $maker->quote_literal($_) : $_) =~ s/\n/\\\n\t/g; $temp } @{$elements};
}

sub make_entry {
	my ($maker, $node) = @_;
	my @commands = map { escape_command($maker, $_) } $node->to_command(perl => '$(ABSPERLRUN)');
	return join "\n\t", $node->target . ' : ' . join(' ', $node->dependencies), @commands;
}

sub postamble {
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
 use ExtUtils::MakeMaker::Plan -global;
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

This MakeMaker extension consumes ExtUtils::Builder::Plan objects, converting them into the Makefile. It's used by passing on the plans using the postamble.plans argument of WriteMakefile. It can be loaded in two ways, depending on your need.

=over 4

=item * Global.

This can be done by giving the use statement a -global argument. This will install ExtUtils::MakeMaker::Plan's as the global postamble. This is the easiest method of using it, but is not compatible with using other postamble extensions to MakeMaker. This is equivalend to:

 package MY;
 use ExtUtils::MakeMaker::Plan 'postamble';

=item * Non-global

This usually means that you have your own postamble, which calls back this modules postambles and others, and concatenates them. For example:

 my @extensions = ('ExtUtils::MakeMaker::Plan', ...);
 load($_) for extensions
 my @methods = map { my $method = $extension . "::postamble" } @extensions;
 sub MY::postamble {
   my ($makemaker, %args) = @_;
   return join "\n\n", map { $makemaker->$_(%args) } @methods;
 }

=back

=func postamble($makemaker, %args)

This generates a postamble for C<$makemaker> into a postamble section in the makefile from the plans in C<$args{plans}>>

=func make_entry($makemaker, $node)

This takes a L<Node|ExtUtils::Builder::Node> object and turns it into a makefile entry.

=func escape_command($makemaker, $elements)

Escape a command for inclusion in a makefile line. C<$elements> is an array-ref containing the elements of the command (e.g. C<['echo', 'Hello', 'World!']>).
