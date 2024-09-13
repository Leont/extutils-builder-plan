package ExtUtils::Builder::Planner;

use strict;
use warnings;

use Carp ();
use File::Spec;
use List::Util 1.45 ();

use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Node;
use ExtUtils::Builder::Util;

my $class_counter = 0;

sub new {
	my $base_class = shift;
	return $base_class->_new_scope($base_class, {});
}

sub _new_scope {
	my ($self, $base_class, $nodes) = @_;

	my $class = __PACKAGE__ . '::Anon_' . ++$class_counter;
	no strict 'refs';
	push @{ "$class\::ISA" }, $base_class;

	bless {
		nodes => $nodes,
	}, $class;
}

sub new_scope {
	my ($self) = @_;
	return $self->_new_scope(ref($self), $self->{nodes});
}

sub add_node {
	my ($self, $node) = @_;
	my $target = $node->target;
	if (exists $self->{nodes}{$target}) {
		Carp::croak("Duplicate for target $target") if !$node->mergeable or !$self->{nodes}{$target}->mergeable;
		my @dependencies = List::Util::uniq($self->{nodes}{$target}->dependencies, $node->dependencies);
		my $new = ExtUtils::Builder::Node->new(target => $target, dependencies => \@dependencies, phony => 1);
		$self->{nodes}{$target} = $new;
	} else {
		$self->{nodes}{$target} = $node;
	}
	return $node->target;
}

sub create_node {
	my ($self, %args) = @_;
	my $node = ExtUtils::Builder::Node->new(%args);
	return $self->add_node($node);
}

sub create_phony {
	my ($self, $target, @dependencies) = @_;
	return $self->create_node(
		target       => $target,
		dependencies => \@dependencies,
		type         => 'phony',
	);
}

sub add_plan {
	my ($self, $plan) = @_;
	$self->add_node($_) for $plan->nodes;
	return;
}

my $set_subname = eval { require Sub::Util; Sub::Util->VERSION('1.40'); \&Sub::Util::set_subname } || sub { $_[1] };

sub add_delegate {
	my ($self, $name, $sub) = @_;
	my $full_name = ref($self) . '::' . $name;
	no strict 'refs';
	no warnings 'redefine';
	*{$full_name} = $set_subname->($full_name, $sub);
	return;
}

sub load_module {
	my ($self, $plannable, $version, %options) = @_;
	ExtUtils::Builder::Util::require_module($plannable);
	$plannable->VERSION($version) if $version;
	return $plannable->add_methods($self, %options);
}

sub materialize {
	my $self = shift;
	my %nodes = %{ $self->{nodes} };
	return ExtUtils::Builder::Plan->new(nodes => \%nodes);
}

my %dsl_commands = (
	command => sub {
		my (@command) = @_;
		return ExtUtils::Builder::Action::Command->new(command => \@command);
	},
	code => sub {
		my %args = @_;
		return ExtUtils::Builder::Action::Code->new(%args);
	},
	function => sub {
		my %args = @_;
		return ExtUtils::Builder::Action::Function->new(%args);
	},
);
$set_subname->($_, $dsl_commands{$_}) for keys %dsl_commands;

sub run_dsl {
	my ($self, $filename) = @_;

	my $dsl_module = ref($self) . '::DSL';

	if (not defined &{ "$dsl_module\::AUTOLOAD" }) {
		no strict 'refs';
		*{ "$dsl_module\::AUTOLOAD" } = sub {
			my $name = our $AUTOLOAD;
			$name =~ s/.*:://;
			if (my $method = $self->can($name)) {
				my $delegate = $set_subname->($name, sub {
					$self->$method(@_);
				});
				*{ "$dsl_module\::$name" } = $delegate;
				goto &$delegate;
			}
			else {
				Carp::croak("No such subroutine $name");
			}
		};

		for my $name (keys %dsl_commands) {
			*{ "$dsl_module\::$name" } = $dsl_commands{$name} if not $dsl_module->can($name);
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
 );
 my $plan = $planner->materialize;

=head1 DESCRIPTION

=method add_node($node)

This adds an L<ExtUtils::Builder::Node|ExtUtils::Builder::Node> to the planner.

=method create_node(%args)

This creates a new node and adds it to the planner using C<add_node>. It takes the same named arguments as C<ExtUtils::Builder::Node>.

=over 4

=item * target

The target of the node. This is mandatory.

=item * dependencies

The list of dependencies for this node.

=item * actions

The actions to perform to create or update this node.

=item * type

This marks the type of the node: C<file> or C<phony>, defaulting to the former.

=back

=method add_plan($plan)

This adds all nodes in the plan to the planner.

=method add_delegate($name, $sub)

This adds C<$sub> as a helper method to this planner, with the name C<$name>.

=method create_phony($target, @dependencies)

This is a helper function that calls C<create_node> for a action-free phony target.

=method load_module($extension, $version, %options)

This adds the delegate from the given module. If C<$version> is defined it will verify if the extension is at least that version.

=method new_scope()

This opens a new scope on the planner. It return a child planner that shared the build tree state with its parent, but any delegated added to it will not be added to the parent.

=method run_dsl($filename)

This runs C<$filename> as a DSL file. This is a script file that includes Planner methods as functions. For example:

 use strict;
 use warnings;

 create_node(
     target       => 'foo',
     dependencies => [ 'bar' ],
     actions      => [
		command(qw/echo Hello World!/),
		function(module => 'Foo', function => 'bar'),
		code(code => 'print "Hello World"'),
	 ],
 );

 load_module("Foo");

 add_foo("a.foo", "a.bar");

This will also add C<command>, C<function> and C<code> helper functions that correspond to L<ExtUtils::Builder::Action::Command>, L<ExtUtils::Builder::Action::Function> and L<ExtUtils::Builder::Action::Code> respectively.

=method materialize()

This returns a new L<ExtUtils::Builder::Plan|ExtUtils::Builder::Plan> object based on the planner.

=begin Pod::Coverage

new

=end Pod::Coverage
