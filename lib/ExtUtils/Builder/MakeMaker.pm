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

my $escape_command = sub {
	my ($maker, $elements) = @_;
	return join ' ', map { (my $temp = m{[^\w/\$().-]} ? $maker->quote_literal($_) : $_) =~ s/\n/\\\n\t/g; $temp } @{$elements};
};

my %double_colon = map { $_ => 1 } qw/all pure_all subdirs config dynamic static clean distdir test install/;
my $make_entry = sub {
	my ($maker, $target, $dependencies, $actions) = @_;
	my @commands = map { $maker->$escape_command($_) } map { $_->to_command(perl => '$(ABSPERLRUN)') } @{$actions};
	my $quote_dep = $maker->can('quote_dep') || sub { $_[1] };
	my @dependencies = map { $maker->$quote_dep($_) } @{$dependencies};
	my $colon = $double_colon{$target} ? '::' : ':';
	return join "\n\t", join(' ', $target, $colon, @dependencies), @commands;
};

sub postamble {
	my ($maker, %args) = @_;
	my @ret = $maker->SUPER::postamble(%args);

	my $planner = ExtUtils::Builder::Planner->new;

	$maker->make_plans($planner, %args) if $maker->can('make_plans');
	for my $file (glob 'planner/*.pl') {
		$planner->run_dsl($file);
	}

	my $plan = $planner->materialize;
	push @ret, map { $maker->$make_entry($_->target, [ $_->dependencies ], [ $_ ]) } $plan->nodes;
	unshift @ret, $maker->$make_entry('pure_all', [ $plan->roots ]) if $plan->roots;

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

This MakeMaker extension will call your C<MY::make_plans> method with a L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner> as argument so that you can add entries to it; these entries will be added to your Makefile. It will also call any C<.pl> files in C</planner> as DSL files. Entries may depend on existing MakeMaker entries and vice-versa; The roots, if any, will be added as dependencies of C<pure_all>.

=begin Pod::Coverage

postamble

=end Pod::Coverage
