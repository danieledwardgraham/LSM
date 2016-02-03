#!/usr/bin/perl
# CGI Program: v.1.0, 11/2009, Dan Graham
use strict;
use warnings;

use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Template;
use Time::Local;
use Data::Dumper;

$| = 1;

$ENV{LD_LIBRARY_PATH}=":/home/dgraham/mysql-server/mysql-5.1.37-linux-i686-icc-glibc23/lib";
$ENV{LD_RUN_PATH}="/home/dgraham/mysql-server/mysql-5.1.37-linux-i686-icc-glibc23/lib";

my $cgi = CGI->new(  );

my ($param, $template);
#my $ROOTDIR = '/home/dgraham/Apache/httpd-2.2.14/htdocs';
my $ROOTDIR = '/var/lib/openshift/56afccde89f5cf39b300003b/app-root/runtime/repo/GUI/htdocs';

#my $ROOTURL = '/home/dgraham/Apache/httpd-2.2.14/htdocs';
my $ROOTURL = '/var/lib/openshift/56afccde89f5cf39b300003b/app-root/runtime/repo/GUI/htdocs';

#my $ROOTCGI = '/home/dgraham/Apache/httpd-2.2.14/cgi-bin/LSM';
my $ROOTCGI = '/var/lib/openshift/56afccde89f5cf39b300003b/app-root/runtime/repo/GUI/cgi-bin/LSM';

my (@hrArr, $ind, $val);
for (my $i = 0; $i < 24; $i++) {
    $ind = sprintf("%02d", $i); 
    $val = ($i == $cgi->param('statHour')) ? 1:0;
    push @hrArr, { ind => "$ind", val => "$val" };
}

my $vars = { 
    rootdir => $ROOTDIR,
    rooturl => $ROOTURL,
    rootcgi => $ROOTCGI,
    hrArr => \@hrArr
};


$template = 'lsm_treeSelector.html';

my %ignore;
open (INFILE, "topid.ignore");
foreach my $x (<INFILE>) {
    chomp($x);
    $ignore{"$x"} = 1;
}
close(INFILE);
my $tt  = Template->new(INCLUDE_PATH => ["$ROOTDIR"], RECURSION => 'On');
print $cgi->header(  );
open (INFILE, "lsm_db.conf") or die "Could not find database config file, lsm_db.conf";
my $conf = join('', map {chomp && $_} <INFILE>);
close(INFILE);
my %conf = split(/[\=\;\,]/, $conf);
my $DBH = DBI->connect("DBI:mysql:$conf{'DBNAME'};host=$conf{'HOST'};port=$conf{'PORT'}", $conf{'USER'}, $conf{'PASSWORD'} 
	           ) || die("Could not connect to database: $DBI::errstr \n");

#my ($year, $mon, $mday) = split(/\-/, $cgi->param('statDate'));
my ($year, $mon, $mday) = split(/\-/, $cgi->param('GMTDate'));
#my %dt = ( JAN => '01', FEB => '02', MAR => '03',
#           APR => '04', MAY => '05', JUN => '06',
#           JUL => '07', AUG => '08', SEP => '09',
#           OCT => '10', NOV => '11', DEC => '12');
#$mon = $dt{$mon};
#my $hour = $cgi->param('statHour');
my $hour = $cgi->param('GMTHour');
my ($min, $sec) = (0, 0);
my $period = $cgi->param('period');
my ($sumTime1, $sumTime2, $epochTime);
$sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, "00", "00") if ($period eq "hourly");
$sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, "00", "00", "00") if ($period eq "daily");
$sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, "59", "59") if ($period eq "hourly");
$sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, "23", "59", "59") if ($period eq "daily");
$sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon + 1, "01", "00", "00", "00") if ($period eq "monthly");
if ($period eq "monthly") {
    $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, "01", "00", "00", "00");
    if ($mon == 12) {
        $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1, "01", "01", "00", "00", "00");
    } else {
        $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon + 1, "01", "00", "00", "00");
    }
}
my ($wday, $yday, $isdst);
if ($period eq "weekly") {
    $year -= 1900;
    $epochTime = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($epochTime);
    my ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2) = localtime($epochTime - ($hour * 60 * 60 + $min * 60 + $sec) - ($wday * 24 * 60 * 60));
    $year2 += 1900;
    $mon2++;
    $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year2, $mon2, $mday2, "00", "00", "00");
    ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2) = localtime($epochTime - ($hour * 60 * 60 + $min * 60 + $sec) - ($wday * 24 * 60 * 60) + (7 * 24 * 60 * 60));
    $year2 += 1900;
    $mon2++;
    $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year2, $mon2, $mday2, "00", "00", "00");
}

#my ($yday, $isdst);
#($year, $mon, $mday, $hour, $min, $sec) = split(/[\- \:]/, $sumTime1);
#$year -= 1900;
#if ($period eq "hourly") {
#    $epochTime = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);
#} else { 
#    $epochTime = timegm($sec, $min, $hour, $mday, $mon - 1, $year);
#}
#($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime($epochTime);
#$year += 1900;
#$mon++;

#my $GMTIME1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
my $GMTIME1 = $sumTime1;

#($year, $mon, $mday, $hour, $min, $sec) = split(/[\- \:]/, $sumTime2);
#$year -= 1900;
#if ($period eq "hourly") {
#    $epochTime = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);
#} else { 
#    $epochTime = timegm($sec, $min, $hour, $mday, $mon - 1, $year);
#}
#($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime($epochTime);
#$year += 1900;
#$mon++;

#my $GMTIME2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
my $GMTIME2 = $sumTime2;

my ($TBLNM, $COLNM);
if ($period eq "hourly") {
    $TBLNM = "hourly_agg";
    $COLNM = "time_hour";
} else {
    if ($period eq "daily") {
        $TBLNM = "daily_agg";
        $COLNM = "time_day";
    } else {
        if ($period eq "weekly") {
            $TBLNM = "weekly_agg";
            $COLNM = "time_week";
        } else {
            if ($period eq "monthly") {
                $TBLNM = "monthly_agg";
                $COLNM = "time_month";
            }
        }
    }
}

$vars->{"statHour"} = $cgi->param('statHour');
$vars->{"statDate"} = $cgi->param('statDate');
$vars->{"period"} = $period;
#$vars->{"sumTime1"} = $sumTime1;
#$vars->{"sumTime2"} = $sumTime2;
$vars->{"GMTIME1"} = $GMTIME1;
$vars->{"GMTIME2"} = $GMTIME2;
$vars->{"GMTDIFF"} = $cgi->param('GMTDiff');
$vars->{"tree"} = computeTree(1, "*", "TKey1='root'", "", "Key1='*'");

#print Dumper($vars->{"tree"});
$tt->process($template, $vars)
    || die $tt->error(  );

$DBH->disconnect();
 
sub computeTree {
    my $keyNo = shift;
    my $keyVal = shift;
    my $TKeyStr = shift;
    my $keyStr = shift;
    my $keyWhere = shift;
    my $retHash = { };
    my @hashArr;
    my @arrArr;
    my $hc = 0;
    my $ac = 0;
    my $nextKeyNo = $keyNo + 1;
    return $retHash if ($nextKeyNo > 15);
    $retHash->{"key"} = $keyVal;
    $keyStr .= "&Key$keyNo"."=$keyVal";
    $retHash->{"keyStr"} = $keyStr; 
    my $nodes = [ ];
    my $sth = $DBH->prepare("select distinct TKey$nextKeyNo from topo_def where $TKeyStr order by TKey$nextKeyNo");
    my $rv = $sth->execute();
    die "database error: $DBH->errstr" if (!defined($rv));
    my $remWhere;
    for (my $i = $nextKeyNo + 1; $i<=15; $i++) {
        $remWhere .= " and TKey$i='*'";
    } 
    my $resArr = $sth->fetchall_arrayref({});
    my ($newTKeyStr, $newKeyVal, $res, $topId, @bindArr, $node, $newKeyWhere, $vals);
    foreach my $TKey (@$resArr) {
        next if ($TKey->{"TKey$nextKeyNo"} eq "*");
        $newTKeyStr = $TKeyStr . " and TKey$nextKeyNo"."='".$TKey->{"TKey$nextKeyNo"}."'";
        $sth = $DBH->prepare("select TopId from topo_def where ".$newTKeyStr.$remWhere);
        $rv = $sth->execute();
        die "database error: $DBH->errstr" if (!defined($rv));
        $res = $sth->fetchrow_hashref();
        $topId = $res->{"TopId"};
        next if (defined($ignore{"$topId"}));
        $sth = $DBH->prepare("select TKeyDesc$nextKeyNo from topo_desc where TopId=?");
        @bindArr = ( $topId );
        $rv = $sth->execute(@bindArr);
        die "database error: $DBH->errstr" if (!defined($rv));
        $res = $sth->fetchrow_hashref();
        $hashArr[$hc] = { };
        $node = $hashArr[$hc++];
        $node->{"TopId"} = $topId;
        $node->{"TKey"} = $res->{"TKeyDesc$nextKeyNo"};
        $arrArr[$ac] = [ ];
        $vals = $arrArr[$ac++];
        $sth = $DBH->prepare("select distinct Key$nextKeyNo from $TBLNM use index ($TBLNM"."_ind".($nextKeyNo).") where TopId=? and $keyWhere and $COLNM=str_to_date(?, '%Y-%m-%d %H:%i:%s') order by Key$nextKeyNo");
        @bindArr = ( $topId, $GMTIME1 );
        $rv = $sth->execute(@bindArr);
        die "database error: $DBH->errstr" if (!defined($rv));
        while ($res = $sth->fetchrow_hashref()) {
            $newKeyWhere = $keyWhere . " and Key$nextKeyNo='".$res->{"Key$nextKeyNo"}."'";
            push @$vals, computeTree($nextKeyNo, $res->{"Key$nextKeyNo"}, $newTKeyStr, $keyStr, $newKeyWhere);
        }  
        $node->{"Vals"} = $vals;
        push @$nodes, $node;
    } 
    $retHash->{"Nodes"} = $nodes;
    return $retHash;
}

