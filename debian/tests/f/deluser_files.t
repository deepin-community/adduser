#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

sub create_files_in_homedir{
    my ($acct, $uid, $gid) = @_;
    mkdir ("/home/$acct", 0777);
    mkdir ("/home/$acct/mnt", 0777);
    mkdir ("/home/$acct/dir", 0777);
    mkdir ("/tmp/$acct", 0777);
    unlink("/tmp/foo.txt");
    for ("/home/$acct/extra.txt", "/tmp/$acct/extra2.txt", "/tmp/foo.txt") {
        open (XTRA, '>', $_) || die ("could not open file $_: $!");
        print XTRA "extra file";
        close (XTRA) || die ('could not close file!');
    }
    system ('mkfifo', "/home/$acct/pipe");
    chown ($uid, $gid, 
        "/home/$acct", 
        "/home/$acct/extra.txt",
        "/tmp/$acct/extra2.txt",
        "/home/$acct/mnt",
        "/home/$acct/dir",
        "/tmp/foo.txt",
        "/home/$acct/pipe");
    assert_command_success('mount','-o','bind',"/tmp/$acct","/home/$acct/mnt");
}

END {
    # remove_tree('/home/foo');
    # remove_tree('/var/mail/foo');
    system("umount /home/foo-extra/mnt >/dev/null 2>/dev/null");
    remove_tree('/home/foo-extra');
    remove_tree('/tmp/foo-extra');
    unlink('/tmp/foo.tar.gz'); 
    unlink('/tmp/foo.txt');
}

assert_user_does_not_exist('foo');
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', 
    '--home', '/home/foo',
    'foo');
assert_user_exists('foo');

my ($login, $pass, $uid, $gid) = getpwnam('foo');
create_files_in_homedir("foo-extra", $uid, $gid);

assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--backup-suffix', 'gz',
    '--remove-all-files',
    '--backup-to', '/tmp',
    'foo');
system("umount /home/foo-extra/mnt >/dev/null 2>/dev/null");
assert_user_does_not_exist('foo');
assert_path_does_not_exist('/home/foo');
assert_path_does_not_exist('/home/foo-extra/extra.txt');
assert_path_does_not_exist('/home/foo-extra/pipe');
#FIXME
#assert_path_does_not_exist('/tmp/foo-extra/extra2.txt');
assert_path_exists('/tmp/foo.txt');
assert_path_exists('/home/foo-extra/mnt');
assert_path_does_not_exist('/home/foo-extra/dir');

# check backup archive
assert_path_exists('/tmp/foo.tar.gz');
my $tar_files = `tar tf /tmp/foo.tar.gz`;
is($? >> 8, 0, 'successfully listed backup files');
like($tar_files, qr{home/foo-extra/extra.txt}, 'archive contains expected file: extra.txt');

assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', 
    '--home', '/home/foo',
    'foo');
assert_user_exists('foo', $uid, $gid);
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--remove-all-files',
    '--backup-to', '/nonexistent',
    'foo');
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', 
    '--home', '/home/foo',
    'foo');
assert_user_exists('foo', $uid, $gid);
($login, $pass, $uid, $gid) = getpwnam('foo');
create_files_in_homedir("foo-extra", $uid, $gid);
assert_command_failure_silent('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--remove-all-files',
    '--backup-to', '/nonexistent',
    'foo');
assert_user_exists('foo');
assert_path_exists('/home/foo');
assert_path_exists('/home/foo-extra/extra.txt');
assert_path_exists('/home/foo-extra/pipe');
#FIXME
#assert_path_does_not_exist('/tmp/foo-extra/extra2.txt');
assert_path_exists('/tmp/foo.txt');
assert_path_exists('/home/foo-extra/mnt');
assert_path_exists('/home/foo-extra/dir');
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--remove-all-files',
    '--backup-to', '/tmp',
    'foo');
system("umount /home/foo-extra/mnt >/dev/null 2>/dev/null");
assert_user_does_not_exist('foo');
assert_path_does_not_exist('/home/foo');
assert_path_does_not_exist('/home/foo-extra/extra.txt');
assert_path_does_not_exist('/home/foo-extra/pipe');
#FIXME
#assert_path_does_not_exist('/tmp/foo-extra/extra2.txt');
assert_path_exists('/tmp/foo.txt');
assert_path_exists('/home/foo-extra/mnt');
assert_path_does_not_exist('/home/foo-extra/dir');

# vim: tabstop=4 shiftwidth=4 expandtab
