package ExtUtils::Builder;

use strict;
use warnings;

1;

#ABSTRACT: An abstract representation of build processes

=head1 DESCRIPTION

Writing extensions for various build tools can be a daunting task. This module tries to abstract steps of build processes into reusable building blocks for creating platform and build system agnostic executable descriptions of work. This allows producing and consuming sides to be completely independent from each other.

These build steps can be used directly (e.g. L<Dist::Build>) or be converted into Makefile.

=head1 OVERVIEW

=head2 Action basics

Actions are the cornerstone of the ExtUtils::Builder framework. It is a flexible abstraction around steps of a process, it can be a piece of perl code or an external command.

=head3 Nodes

Nodes describe how a target should be created. Every node has an unordered set of zero or more dependencies that must be build (and must be up-to-date) before the target is build. It also has a list of actions to perform (in order) to create (or recreate) the target file. Essentially, a Node is equivalent to entry in a Makefile.

=head2 Plans

Plans are the equivalent of a (piece of a) Makefile. They are a bunch of nodes that should interconnect.

The C<run> method will create the given target and all its dependencies in a topological order much like C<make>. It will check which steps are necessary and skip the ones which are not. Alternatively it can be serialized to a JSON-compatible datastructure (and later deserialized) using L<ExtUtils::Builder::Serializer>, or even integrated into L<ExtUtils::MakeMaker> using L<ExtUtils::Builder::MakeMaker>.

=head2 Planners

A Planner is an object used to create Plans. At the base level it allows you to add nodes or pattern matches/substitutions, but usually one would load extensions that add higher level methods to the planner (e.g. C<compile>). Planners support scopes: child planners that share the build plan but contain extra helper methods. It also supports DSL scripts: these are perl scripts that support calling the planner's methods as functions for easy customization of build plans.
