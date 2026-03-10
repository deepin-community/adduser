#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


END {
    remove_tree('/home/foo');
    remove_tree('/var/mail/foo');
}

assert_user_does_not_exist('foo');
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'foo');
assert_user_exists('foo');

my $output = `/usr/sbin/deluser --stdoutmsglevel=error --stderrmsglevel=error foo 2>&1`;
is($output, '', 'option "--stdoutmsglevel=error" silences deluser output under normal use');

assert_user_does_not_exist('foo');

# vim: tabstop=4 shiftwidth=4 expandtab
