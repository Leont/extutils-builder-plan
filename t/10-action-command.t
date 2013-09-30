#! perl

use strict;
use warnings;

use Test::More 0.89;

use ExtUtils::Builder::Action::Command;
use Test::Fatal;

my $action;
is(exception { $action = ExtUtils::Builder::Action::Command->new(command => [ $^X, '-e0' ]) }, undef, 'Can create new object');

is_deeply($action->to_command, [$^X, '-e0'], 'Returns perl -e0');

like($action->to_code, qr/ \Q$^X\E .+? -e0 /x, 'to_code returns something that might be sensible');

is(exception { $action->execute(quiet => 1) }, undef, 'Can execute quiet command');

my @messages;
is(exception { $action->execute(logger => sub { push @messages, @_ }) }, undef, 'Can execute logging command');

is(scalar(@messages), 1, 'Got one message');
like($messages[0], qr/\Q$^X\E .+ -e0 \z/x, "Got '$^X -e0' as message");

is($action->preference, 'command', 'Preferred action is "execute"');

done_testing;

