#!/usr/bin/perl
# Program : testProbe.pl
# This program tests a probe and prints results to socket server.
# v.1.0, Dan Graham, 10/8/2009

use trafshowProbe;
use Sys::Hostname;
$ENV{"LSM_SERVERPORT"} = 9000;

my $server = hostname();

my $probe = trafshowProbe->new({'secs' => 60*5, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});

$probe->start();

#sleep(120);

#$probe->stop();

