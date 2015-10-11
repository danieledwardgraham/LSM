#!/usr/bin/perl
# Program : testProbe.pl
# This program tests a probe and prints results to the sample.xml file
# v.1.0, Dan Graham, 10/8/2009

use lastProbeTest;
use Sys::Hostname;
$ENV{"LSM_SERVERPORT"} = 9000;

my $server = hostname();

open (OUTFILE, ">sample.xml");
print OUTFILE "<root>";
close(OUTFILE);

my $probe = lastProbeTest->new({'secs' => 30, 'baseTopo' => [{'site' => 'stpaul'},{'server' => $server}]});

$probe->start();

sleep(120);

$probe->stop();

open (OUTFILE, ">>sample.xml");
print OUTFILE "</root>";
close(OUTFILE);
