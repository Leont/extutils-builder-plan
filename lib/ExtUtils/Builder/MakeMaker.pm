package ExtUtils::Builder::MakeMaker;

use strict;
use warnings;

our @ISA;

use ExtUtils::MakeMaker 6.68;
use ExtUtils::Builder::Planner;
use ExtUtils::Config::MakeMaker;
use ExtUtils::Manifest ();

sub import {
	my ($class, @args) = @_;
	if (!MM->isa(__PACKAGE__)) {
		@ISA = @MM::ISA;
		@MM::ISA = __PACKAGE__;
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
	my @dependencies = map { $maker->quote_dep($_) } @{$dependencies};
	my $colon = $double_colon{$target} ? '::' : ':';
	return join "\n\t", join(' ', $target, $colon, @dependencies), @commands;
};

sub postamble {
	my ($maker, %args) = @_;
	my @ret = split "\n\n", $maker->SUPER::postamble(%args);

	my $planner = ExtUtils::Builder::Planner->new;
	$planner->add_delegate('makemaker', sub { $maker });
	my $config = ExtUtils::Config::MakeMaker->new($maker);
	$planner->add_delegate('config', sub { $config });
	$planner->add_delegate('distribution', sub { $maker->{DIST_NAME} });
	$planner->add_delegate('distribution_version', sub { $maker->{VERSION} });
	$planner->add_delegate('main_module', sub { $maker->{NAME} });
	$planner->add_delegate('pureperl_only', sub { $maker->{PUREPERL_ONLY} });
	$planner->add_delegate('perl_path', sub { $maker->{ABSPERLRUN} });
	$planner->add_delegate('uninst', sub { $maker->{UNINST} });
	$planner->add_delegate('meta', sub { CPAN::Meta->load_file('META.json') });
	$planner->add_delegate('release_status', sub { CPAN::Meta->load_file('META.json')->release_status });
	$planner->add_delegate('jobs', sub { 1 });

	$planner->add_delegate('new_planner', sub {
		my $inner = ExtUtils::Builder::Planner->new;
		$inner->add_delegate('config', sub { $config });
		return $inner;
	});

	$planner->add_seen($_) for sort keys %{ ExtUtils::Manifest::maniread() };

	$maker->make_plans($planner, %args) if $maker->can('make_plans');
	for my $file (glob 'planner/*.pl') {
		my $inner = $planner->new_scope;
		$inner->add_delegate('self', sub { $inner });
		$inner->add_delegate('outer', sub { $planner });
		$inner->run_dsl($file);
	}

	my $plan = $planner->materialize;
	push @ret, map { $maker->$make_entry($_->target, [ $_->dependencies ], [ $_ ]) } $plan->nodes;

	if ($maker->is_make_type('gmake') || $maker->is_make_type('bsdmake')) {
		my @phonies = grep { !$double_colon{$_} } $plan->phonies;
		push @ret, $maker->$make_entry('.PHONY', \@phonies) if @phonies
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

This MakeMaker extension will call your C<MY::make_plans> method with a L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner> as argument so that you can add entries to it; these entries will be added to your Makefile. It will also call any C<.pl> files in C</planner> as DSL files, these are run in a new scope so delegates don't leak out. Entries may depend on existing MakeMaker entries and vice-versa. Typically one would make their target a dependency of a MakeMaker entry like C<pure_all> or C<dynamic>.

=begin Pod::Coverage

postamble

=end Pod::Coverage
