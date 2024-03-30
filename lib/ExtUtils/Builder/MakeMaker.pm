package ExtUtils::Builder::MakeMaker;

use strict;
use warnings;

our @ISA;

use ExtUtils::MakeMaker;
use ExtUtils::Builder::Planner;

sub import {
	my ($class, @args) = @_;
	if (!MM->isa('ExtUtils::Builder::MakeMaker')) {
		@ISA = @MM::ISA;
		@MM::ISA = qw/ExtUtils::Builder::MakeMaker/;
		splice @ExtUtils::MakeMaker::Overridable, -1, 0, 'make_plans';
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

	if ($maker->can('make_plans')) {
		my $planner = ExtUtils::Builder::Planner->new;
		$maker->make_plans($planner);
		my $plan = $planner->materialize;

		push @ret, map { make_entry($maker, $_->target, [ $_->dependencies ], [ $_ ]) } $plan->nodes;

		my $quote_dep = $maker->can('quote_dep') || sub { $_[1] };
		unshift @ret, 'pure_all :: ' . join ' ', map { $maker->$quote_dep($_) } $plan->roots if $plan->roots;
	}
	return join "\n\n", @ret;
}

1;

#ABSTRACT: A MakeMaker consumer for ExtUtils::Builder Plan objects

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 use ExtUtils::Builder::MakeMaker;
 ...
 WriteMakeFile(
   NAME => 'Foo',
   VERSION => 0.001,
 );

 sub MY::make_plans {
   my ($self, $planner) = @_;
   $planner->load_module('Some::Module');
   ... # Add plans to $planner
 }

=head1 DESCRIPTION

This MakeMaker extension will call your C<MY::make_plans> method with a L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner> as argument so that you can add entries to it. These entries will be added to your Makefile. The roots, if any, will be added as dependencies of C<pure_all>.

=begin Pod::Coverage

postamble
make_entry
escape_command

=end Pod::Coverage
