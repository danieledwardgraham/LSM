#!/usr/bin/perl
# Program : testProbe.pl
# This program tests a probe and prints results to socket server.
# v.1.0, Dan Graham, 10/8/2009

use trafshowProbe;
use Sys::Hostname;
use POSIX qw(setsid);
$ENV{"LSM_SERVERPORT"} = 9000;

my $server = hostname();

my $probe = trafshowProbe->new({'secs' => 60*5, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});

local $SIG{'TERM'} = sub {
    $probe->stop();
    exit(0);
};

$probe->start();
sleep 5;
my $pid = fork;
die "could not fork" if (!defined($pid));
exit if ($pid > 0);

setsid();

while (1) {
    sleep 5;
}
