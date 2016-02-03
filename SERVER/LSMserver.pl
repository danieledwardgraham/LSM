#!/usr/bin/perl
use strict;
use server;

$ENV{"LSM_SERVERPORT"} = 9000;

my $obj = server->new({host => $ENV{'OPENSHIFT_MYSQL_DB_HOST'}, port => 9000, dbport => $ENV{'OPENSHIFT_MYSQL_DB_PORT'}, user => 'adminus7wB1b', password => 'eR3X_Dy5ne_Y', dbname => 'lsm',
                       aggHourInt => 60*5, aggDayInt => 60*10, aggWeekInt => 60*10, aggMonthInt => 60*10});

local $SIG{'TERM'} = sub {
    $obj->stop();
    exit(0);
};

$obj->start();

while (1) {
    sleep 10;
}
