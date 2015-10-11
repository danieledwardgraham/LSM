#!/usr/bin/perl
# Program : testProbe.pl
# This program tests a probe and prints results to socket server.
# v.1.0, Dan Graham, 10/8/2009

use topProbe;
use lastProbe;
use dfProbe;
use Sys::Hostname;
use POSIX qw(setsid);
use strict;
$ENV{"LSM_SERVERPORT"} = 9000;

my $server = hostname();

my $probe = topProbe->new({'secs' => 60*5, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});
my $probe2 = lastProbe->new({'secs' => 60*5, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});
my $probe3 = dfProbe->new({'secs' => 60*5, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});

local $SIG{'TERM'} = sub {
    $probe->stop();
    $probe2->stop();
    $probe3->stop();
    exit(0);
};

$probe->start();
$probe2->start();
$probe3->start();

sleep 5;
my $pid = fork;
die "could not fork" if (!defined($pid));
exit if ($pid > 0);

setsid();

while (1) {
    sleep 5;
}
