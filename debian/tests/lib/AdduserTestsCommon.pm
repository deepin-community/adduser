use diagnostics;
use strict;
use warnings;

use File::Path qw(remove_tree);
use Test::More qw(no_plan);


BEGIN {

    if (-f '/var/cache/adduser/tests/state.tar') {
        return;
    }

    my @conffiles = (
        'etc/adduser.conf',
        'etc/deluser.conf',
        'etc/default/useradd',
        'etc/group',
        'etc/gshadow',
        'etc/login.defs',
        'etc/passwd',
        'etc/shadow',
    );

    mkdir('/var/cache/adduser/tests');
    system('/bin/tar', 'cf', '/var/cache/adduser/tests/state.tar', '--directory=/', @conffiles);
}

END {
    system('/bin/tar', 'xf', '/var/cache/adduser/tests/state.tar', '--directory=/');
}

sub assert_command_success {
    system(@_);
    is($? >> 8, 0, "command success: @_");
}

sub assert_group_does_not_exist {
    my $group = shift;
    is(getgrnam($group), undef, "group does not exist: $group");
}

sub assert_group_exists {
    my $group = shift;
    isnt(getgrnam($group), undef, "group exists: $group");
}

sub assert_group_membership_does_not_exist {
    my ($user, $group) = @_;
    ok(!group_membership_exists($user, $group), "group membership does not exist: $user in $group");
}

sub assert_group_membership_exists {
    my ($user, $group) = @_;
    ok(group_membership_exists($user, $group), "group membership exists: $user in $group");
}

sub group_membership_exists {
    my ($user, $group) = @_;

    my @user_info = getpwnam($user);
    my @group_info = getgrnam($group);

    if (defined($user_info[3]) && defined($group_info[2])) {
        return 1 if $user_info[3] == $group_info[2];
    }

    if (defined($group_info[3])) {
        foreach (split(/ /, $group_info[3])) {
            return 1 if $_ eq $user;
        }
    }

    return 0;
}

sub assert_primary_group_membership_exists {
    my ($user, $group) = @_;
    ok(primary_group_membership_exists($user, $group), "primary group membership exists: $user in $group");
}

sub primary_group_membership_exists {
    my ($user, $group) = @_;

    my @user_info = getpwnam($user);
    my @group_info = getgrnam($group);

    if (defined($user_info[3]) && defined($group_info[2])) {
        return 1 if $user_info[3] == $group_info[2];
    }

    return 0;
}

sub assert_supplementary_group_membership_exists {
    my ($user, $group) = @_;
    ok(supplementary_group_membership_exists($user, $group), "supplementary group membership exists: $user in $group");
}

sub supplementary_group_membership_exists {
    my ($user, $group) = @_;

    my @group_info = getgrnam($group);

    if (defined($group_info[3])) {
        foreach (split(/ /, $group_info[3])) {
            return 1 if $_ eq $user;
        }
    }

    return 0;
}

sub assert_path_does_not_exist {
    my $path = shift;
    ok(! -e $path, "path does not exist: $path");
}

sub assert_path_exists {
    my $path = shift;
    ok(-e $path, "path exists: $path");
}

sub assert_path_has_mode {
    my ($path, $mode) = @_;
    my $name = "path has mode: $path has mode $mode";

    my @info = stat($path);

    if (!@info) {
        fail($name);
        return;
    }

    is(sprintf('%04o', $info[2] & 07777), $mode, $name);
}

sub assert_path_has_ownership {
    my ($path, $ownership) = @_;
    my $name = "path has ownership: $path is owned by $ownership";

    my @info = stat($path);

    if (!@info) {
        fail($name);
        return;
    }

    my $user = getpwuid($info[4]);
    my $group = getgrgid($info[5]);

    if (!defined($user) || !defined($group)) {
        fail($name);
        return;
    }

    is(sprintf('%s:%s', $user, $group), $ownership, $name);
}

sub assert_path_is_a_directory {
    my $path = shift;
    ok(-d $path, "path is a directory: $path");
}

sub assert_path_is_an_empty_directory {
    my $path = shift;
    my $name = "path is an empty directory: $path";

    my $dh;
    if (!opendir($dh, $path)) {
        fail($name);
        return;
    }

    my @entries = readdir $dh;

    # Expect $path/. and $path/.. to count for two entries.
    is(scalar(@entries), 2, $name);
}

sub assert_user_does_not_exist {
    my $user = shift;
    is(getpwnam($user), undef, "user does not exist: $user");
}

sub assert_user_exists {
    my $user = shift;
    isnt(getpwnam($user), undef, "user exists: $user");
}

sub assert_user_has_disabled_password {
    my $user = shift;
    my $name = "user has disabled password: $user";

    my $fh;
    if (!open($fh, '<', '/etc/shadow')) {
        fail($name);
        return;
    }

    while (<$fh>) {
        my @info = split(/:/, $_);

        if ($info[0] eq $user && $info[1] eq '!') {
            pass($name);
            return;
        }
    }

    fail($name);
}

sub assert_user_has_home_directory {
    my ($user, $home) = @_;
    is((getpwnam($user))[7], $home, "user has home directory: ~$user is $home");
}

sub assert_user_has_login_shell {
    my ($user, $shell) = @_;
    is((getpwnam($user))[8], $shell, "user has login shell: $user runs $shell");
}

sub assert_user_has_uid {
    my ($user, $uid) = @_;
    is(getpwnam($user), $uid, "user has uid: uid of $user is $uid");
}

1;
