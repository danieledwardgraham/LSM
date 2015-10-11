#!/usr/bin/perl
# Program : testProbe.pl
# This program tests a probe and prints results to the server socket.
# v.1.0, Dan Graham, 10/8/2009

use topProbe;
use Sys::Hostname;
$ENV{"LSM_SERVERPORT"} = 9000;

my $server = hostname();

my $probe = topProbe->new({'secs' => 30, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});

$probe->start();

sleep(120);

$probe->stop();

