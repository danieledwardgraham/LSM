#!/usr/bin/perl
# Program : testProbe.pl
# This program tests a probe and prints results to socket server.
# v.1.0, Dan Graham, 10/8/2009

use topProbe;
use lastProbe;
use dfProbe;
use Sys::Hostname;
$ENV{"LSM_SERVERPORT"} = 9000;

my $server = hostname();

my $probe = topProbe->new({'secs' => 60*5, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});

local $SIG{'TERM'} = sub {
    $probe->stop();
    exit(0);
};

$probe->start();

while (1) {
    sleep 1000000;
}
