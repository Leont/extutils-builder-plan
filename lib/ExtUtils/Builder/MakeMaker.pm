package ExtUtils::Builder::MakeMaker;

use strict;
use warnings;

use Exporter;
our @EXPORT_OK = qw/postamble make_entry escape_command/;
our @ISA;

sub import {
	my ($class, @args) = @_;
	if (@args == 1 and $args[0] eq '-global') {
		if (!(@MM::ISA == 1 && $MM::ISA[0] eq 'ExtUtils::Builder::MakeMaker')) {
			@ISA = @MM::ISA;
			@MM::ISA = qw(ExtUtils::Builder::MakeMaker);
		}
	}
	else {
		goto &Exporter::import;
	}
	return;
}

sub escape_command {
	my ($maker, $elements) = @_;
	return join ' ', map { (my $temp = m{[^\w/\$().-]} ? $maker->quote_literal($_) : $_) =~ s/\n/\\\n\t/g; $temp } @{$elements};
}

sub make_entry {
	my ($maker, $target, $dependencies, $actions) = @_;
	my @commands = map { escape_command($maker, $_) } map { $_->to_command(perl => '$(ABSPERLRUN)') } @{$actions};
	my $quote_dep = $maker->can('quote_dep') || sub { $_[1] };
	my @dependencies = map { $maker->$quote_dep($_) } @{$dependencies};
	return join "\n\t", $target . ' : ' . join(' ', @dependencies), @commands;
}

sub postamble {
	my ($maker, %args) = @_;
	my @ret = $maker->SUPER::postamble(%args);
	my @all_deps;
	if ($args{plans}) {
		my @plans = ref $args{plans} eq 'ARRAY' ? @{ $args{plans} } : $args{plans};
		for my $plan (@plans) {
			push @all_deps, $plan->roots;
			my @entries = sort { $a->target cmp $b->target } $plan->nodes;
			push @ret, map { make_entry($maker, $_->target, [ $_->dependencies ], [ $_ ]) } @entries;
		}
	}
	if($args{actions}) {
		push @all_deps, 'extra_actions';
		push @ret, make_entry($maker, 'extra_actions', [], [ @{ $args{actions} } ]);
	}
	my $quote_dep = $maker->can('quote_dep') || sub { $_[1] };
	unshift @ret, 'pure_all :: ' . join ' ', map { $maker->$quote_dep($_) } @all_deps if @all_deps;
	return join "\n\n", @ret;
}

1;

#ABSTRACT: A MakeMaker consumer for ExtUtils::Builder Plan objects

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 use ExtUtils::Builder::MakeMaker -global;
 ...
 WriteMakeFile(
   NAME => 'Foo',
   VERSION => 0.001,
 );

 sub MY::postamble {
   my ($self) = @_;
   my @plans = Frobnicator->new->plans;
   $self->SUPER::postamble(plans => \@plans);
 }

=head1 DESCRIPTION

This MakeMaker extension consumes ExtUtils::Builder::Plan objects, converting them into the Makefile. It's used by passing on the plans using the postamble.plans argument of WriteMakefile. It can be loaded in two ways, depending on your needs.

=over 4

=item * Global.

This can be done by giving the use statement a C<-global> argument.

 use ExtUtils::Builder::MakeMaker -global;

This will install ExtUtils::Builder::MakeMaker's as the global postamble. This is the easiest method of using it. You may want to combine it with a custom MY::postamble that creates the appropriate arguments and then calls C<$self->SUPER::postable(%arguments)>.

=item * Non-global

This usually means that you have your own postamble, which calls back this modules postambles and others, and concatenates them.

=back

=func postamble($makemaker, %args)

This generates a postamble for C<$makemaker> into a postamble section in the makefile from the plans in C<$args{plans}> and the actions in C<$args{actions}>.

=func make_entry($makemaker, $target, $dependencies, $actions)

This takes a build-triplet (C<$target, $dependencies, $actions>) and formats it into a makefile entry. C<$target> is supposed to be a simple string containing the name of the target. C<$dependencies> is an array-ref of strings containing the list of dependencies. C<$actions> is supposed to be an array-ref of L<Action|ExtUtils::Builder::Action> objects.

=func escape_command($makemaker, $elements)

Escape a command for inclusion in a makefile line. C<$elements> is an array-ref containing the elements of the command (e.g. C<['echo', 'Hello', 'World!']>).
