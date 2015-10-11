#!/usr/bin/perl
use Time::HiRes qw(usleep);
use DBI;
use POSIX qw(setsid);
use strict;
my $pid = fork;

die "could not fork" if (!defined($pid));
exit if ($pid > 0);

setsid();

my $dbh = DBI->connect("DBI:mysql:information_schema;host=localhost",'mysql','mysql');
my %prof;

my $sth = $dbh->prepare("select info from processlist");
open (OUTFILE, ">profiler.out");
local $SIG{'TERM'} = sub {
    foreach (sort {$prof{"$b"} <=> $prof{"$a"}} (keys %prof)) {
        print OUTFILE "$_ ==> ".$prof{"$_"}."\n";
    }
    close(OUTFILE);
    $sth->finish();
    $dbh->disconnect();
    exit(0);
};

my ($arr, $x, $query);
while (1) {
    die "query error: $dbh->errstr" if (!defined($sth->execute()));
    $arr = $sth->fetchall_arrayref({ });
    die "sth error" if (!defined($arr) && $sth->err);
    foreach $x (@$arr) {
        $query = $x->{"info"};
        $query =~ s/\'(.*?)\'/\'\?\'/g;
        $prof{"$query"} += 1;
    }
    usleep(1000);
}
