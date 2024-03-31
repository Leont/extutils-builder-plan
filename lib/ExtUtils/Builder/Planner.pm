package ExtUtils::Builder::Planner;

use strict;
use warnings;

use Carp ();
use File::Spec;
use List::Util ();

use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Node;

my $class_counter = 0;

sub new {
	my $base_class = shift;
	my $class = $base_class . '::Anon_' . ++$class_counter;
	no strict 'refs';
	push @{ "$class\::ISA" }, $base_class;
	bless {
		nodes => {},
		roots => [],
	}, $class;
}

sub add_node {
	my ($self, $node) = @_;
	my $target = $node->target;
	if (exists $self->{nodes}{$target}) {
		Carp::croak("Duplicate for target $target") if !$node->mergeable or !$self->{nodes}{$target}->mergeable;
		my @dependencies = List::Util::uniq($self->{nodes}{$target}->dependencies, $node->dependencies);
		my $new = ExtUtils::Builder::Node->new(target => $target, dependencies => \@dependencies);
		$self->{nodes}{$target} = $new;
	} else {
		$self->{nodes}{$target} = $node;
	}
	return $node->target;
}

sub create_node {
	my ($self, %args) = @_;
	my $node = ExtUtils::Builder::Node->new(%args);
	$self->add_root($node->target) if $args{root};
	return $self->add_node($node);
}

sub add_root {
	my ($self, $root) = @_;
	push @{ $self->{roots} }, $root;
	return;
}

sub add_plan {
	my ($self, $plan) = @_;
	$self->add_node($_) for $plan->nodes;
	$self->add_root($_) for $plan->roots;
	return;
}

sub add_delegate {
	my ($self, $name, $sub) = @_;
	my $full_name = ref($self) . '::' . $name;
	no strict 'refs';
	*{$full_name} = $sub;
	return;
}

sub _require_module {
	my $module = shift;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	return $module;
}

sub load_module {
	my ($self, $plannable, %options) = @_;
	_require_module($plannable);
	return $plannable->add_methods($self, %options);
}

sub materialize {
	my $self = shift;
	my %nodes = %{ $self->{nodes} };
	my @roots = List::Util::uniq(@{ $self->{roots} });
	return ExtUtils::Builder::Plan->new(nodes => \%nodes, roots => \@roots);
}

my %builtins = map { $_ => 1 } qw/add_node create_node add_root add_plan add_delegate load_module run_dsl/;
my $set_subname = eval { require Sub::Util; Sub::Util->VERSION('1.40'); \&Sub::Util::set_subname } || sub { $_[1] };

sub run_dsl {
	my ($self, $filename) = @_;
	my $dsl_module = ref($self) . '::DSL';

	if (not $dsl_module->can('AUTOLOAD')) {
		no strict 'refs';
		*{ "$dsl_module\::AUTOLOAD" } = sub {
			my $name = our $AUTOLOAD;
			$name =~ s/.*:://;
			if ($builtins{$name} || defined &{ ref($self) . "::$name"}) {
				my $delegate = $set_subname->($name, sub {
					$self->$name(@_);
				});
				*{ "$dsl_module\::$name" } = $delegate;
				goto &$delegate;
			}
			else {
				Carp::croak("No such subroutine $name");
			}
		}
	}

	my $path = File::Spec->file_name_is_absolute($filename) ? $filename : File::Spec->catfile(File::Spec->curdir, $filename);
	eval "package $dsl_module; my \$ret = do \$path; die \$@ if \$@; defined \$ret || !\$!" or die $@ || Carp::shortmess("Can't run $path: $!");
	return;
}

1;

# ABSTRACT: An ExtUtils::Builder Plan builder

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 $planner->create_node(
     target       => 'foo',
     dependencies => [ 'bar' ],
     actions      => \@actions,
     root         => 1,
 );
 my $plan = $planner->materialize;

=head1 DESCRIPTION

=method add_node($node)

This adds an L<ExtUtils::Builder::Node|ExtUtils::Builder::Node> to the planner.

=method create_node(%args)

This creates a new node and adds it to the planner using C<add_node>. It takes the same named arguments as C<ExtUtils::Builder::Node>, except for an extra C<root> argument, which will cause the node to be added to the roots if true.

=method add_root($root)

This adds the given name to the list of roots.

=method add_plan($plan)

This adds all nodes and roots in the plan to the planner.

=method add_delegate($name, $sub)

This adds C<$sub> as a helper method to this planner, with the name C<$name>.

=method load_module($extension, %options)

This adds the delegate from the given module

=method run_dsl($filename)

This runs C<$filename> as a DSL file. This is a script file that includes Planner methods as functions. For example:

 use strict;
 use warnings;

 create_node(
     target       => 'foo',
     dependencies => [ 'bar' ],
     actions      => [ ... ],
     root         => 1,
 );

 load_module("Foo");

 add_foo("a.foo", "a.bar");

=method materialize()

This returns a new L<ExtUtils::Builder::Plan|ExtUtils::Builder::Plan> object based on the planner.

=begin Pod::Coverage

new

=end Pod::Coverage
