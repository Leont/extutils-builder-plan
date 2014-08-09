package ExtUtils::Builder::MakeMaker;

use strict;
use warnings FATAL => 'all';

use Exporter;
our @EXPORT_OK = qw/postamble make_entry escape_command/;

sub import {
	my ($class, @args) = @_;
	if (@args == 1 and $args[0] eq '-global') {
		no warnings 'once';
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
	my ($maker, $target, $dependencies, $actions) = @_;
	my @commands = map { escape_command($maker, $_) } map { $_->to_command(perl => '$(ABSPERLRUN)') } @{$actions};
	return join "\n\t", $target . ' : ' . join(' ', @{$dependencies}), @commands;
}

sub postamble {
	my ($self, %args) = @_;
	my @ret;
	if ($args{plans}) {
		my @plans = ref $args{plans} eq 'ARRAY' ? @{ $args{plans} } : $args{plans};
		push @ret, 'pure_all :: ' . join ' ', map { $_->roots } @plans;
		push @ret, map { make_entry($self, $_->target, [ $_->dependencies ], [ $_ ]) } map { $_->nodes } @plans;
	}
	if($args{actions}) {
		push @ret, 'pure_all :: extra_actions';
		push @ret, make_entry($self, 'extra_actions', [], [ @{ $args{actions} } ]);
	}
	return join "\n\n", @ret;
}

1;

#ABSTRACT: A MakeMaker consumer for ExtUtils::Builder Plan objects

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 use ExtUtils::Builder::MakeMaker -global;
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

This can be done by giving the use statement a -global argument. This will install ExtUtils::Builder::MakeMaker's as the global postamble. This is the easiest method of using it, but is not compatible with using other postamble extensions to MakeMaker. This is equivalend to:

 package MY;
 use ExtUtils::Builder::MakeMaker 'postamble';

=item * Non-global

This usually means that you have your own postamble, which calls back this modules postambles and others, and concatenates them. For example:

 my @extensions = ('ExtUtils::Builder::MakeMaker', ...);
 load($_) for @extensions;
 my @methods = map { $_. "::postamble" } @extensions;
 sub MY::postamble {
   my ($makemaker, %args) = @_;
   return join "\n\n", map { $makemaker->$_(%args) } @methods;
 }

=back

=func postamble($makemaker, %args)

This generates a postamble for C<$makemaker> into a postamble section in the makefile from the plans in C<$args{plans}> and the actions in C<$args{actions}>.

=func make_entry($makemaker, $target, $dependencies, $actions)

This takes a build-triplet (C<$target, $dependencies, $actions>) and formats it into a makefile entry. C<$target> is supposed to be a simple string containing the name of the target. C<$dependencies> is an array-ref of strings containing the list of dependencies. C<$actions> is supposed to be an array-ref of L<Action|ExtUtils::Builder::Role::Action> objects.

=func escape_command($makemaker, $elements)

Escape a command for inclusion in a makefile line. C<$elements> is an array-ref containing the elements of the command (e.g. C<['echo', 'Hello', 'World!']>).
