#!/usr/bin/perl
# statPresent CGI program : D. Graham, 11/2009, v.1.0

use strict;
use warnings;

use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Template;
use Time::Local;
use Data::Dumper;
use GD::Graph::pie;
use GD::Graph::bars;
use GD::Graph::Data;

$| = 1;

$ENV{LD_LIBRARY_PATH}=":/home/dgraham/mysql-server/mysql-5.1.37-linux-i686-icc-glibc23/lib";
$ENV{LD_RUN_PATH}="/home/dgraham/mysql-server/mysql-5.1.37-linux-i686-icc-glibc23/lib";

my $cgi = CGI->new(  );

my ($param, $template);
my $ROOTDIR = '/home/dgraham/Apache/httpd-2.2.14/htdocs';

my $ROOTURL = '/home/dgraham/Apache/httpd-2.2.14/htdocs';

my $ROOTCGI = '/home/dgraham/Apache/httpd-2.2.14/cgi-bin/LSM';

my $vars = { 
    rootdir => $ROOTDIR,
    rooturl => $ROOTURL,
    rootcgi => $ROOTCGI,
};

my @pngFiles = glob("$ROOTDIR/*.png");
my $mtime;
my $now = time();
foreach my $fn (@pngFiles) {
    $mtime = (stat($fn))[9];
    if (($now - $mtime) > 20) {
        unlink($fn);
    }
} 

$template = 'lsm_statPresent.html';

my $tt  = Template->new(INCLUDE_PATH => ["$ROOTDIR"], RECURSION => 'On');
print $cgi->header(  );
open (INFILE, "lsm_db.conf") or die "Could not find database config file, lsm_db.conf";
my $conf = join('', map {chomp && $_} <INFILE>);
close(INFILE);
my %conf = split(/[\=\;\,]/, $conf);
my $DBH = DBI->connect("DBI:mysql:$conf{'DBNAME'};host=$conf{'HOST'}", $conf{'USER'}, $conf{'PASSWORD'} 
	           ) || die("Could not connect to database: $DBI::errstr \n");

my $period = $cgi->param('period');
my ($TBLNM, $COLNM, $TBLNM2, $COLNM2, $xLabel, $dtFormat);
if ($period eq "hourly") {
    $TBLNM = "hourly_agg";
    $COLNM = "time_hour";
} else {
    if ($period eq "daily") {
        $TBLNM = "daily_agg";
        $COLNM = "time_day";
        $TBLNM2 = "hourly_agg";
        $COLNM2 = "time_hour";
        $xLabel = "hours";
        $dtFormat = "%H";
    } else {
        if ($period eq "weekly") {
            $TBLNM = "weekly_agg";
            $COLNM = "time_week";
            $TBLNM2 = "daily_agg";
            $COLNM2 = "time_day";
            $xLabel = "days";
            $dtFormat = "%d";
        } else {
            if ($period eq "monthly") {
                $TBLNM = "monthly_agg";
                $COLNM = "time_month";
                $TBLNM2 = "weekly_agg";
                $COLNM2 = "time_week";
                $xLabel = "weeks";
                $dtFormat = "%d";
            }
        }
    }
}

my $where = "TopId=? and Key1=?";
my $i;
for ($i = 2; $i<=15; $i++) {
    if (defined($cgi->param("Key$i"))) {
        $where .= " and Key$i"."=?";
    } else {
        last;
    }
}
my $indNum = $i - 1;
my $j;
my $counters = [ ];
my $sth = $DBH->prepare("select distinct countTopId, counter from $TBLNM use index ($TBLNM"."_ind".$indNum.") where $where and $COLNM=str_to_date(?, '%Y-%m-%d %H:%i:%s')");
my @bindArr = ( $cgi->param("TopId") );
for ($j = 1; $j < $i; $j++) {
    push @bindArr, $cgi->param("Key$j");
}
push @bindArr, $cgi->param('GMTIME1');

$sth->execute(@bindArr) or die "Database error: ".$DBH->errstr;

my (@hashArr, $node, $sth2, @bindArr2, $res2, $resTKey, $resTKeyDesc, $select, $k, $resMeas, $tbl1, $tbl2, $tbl3, $row, $header, $sumFlag, $avgFlag, $filename, $chartCnt, @chartData, $cd1, $cd2, $chart, $gdData, $nonZeroFlag);
$chartCnt = 1;
my $hashCnt = 0;
while (my $res = $sth->fetchrow_hashref()) {
    $hashArr[$hashCnt] = { };
    $node = $hashArr[$hashCnt++];
    $sth2 = $DBH->prepare("select countDesc from count_desc where TopId=? and counter=?");
    @bindArr2 = ( $res->{"countTopId"}, $res->{"counter"} );
    $sth2->execute(@bindArr2) or die "Database error: ".$DBH->errstr;
    $res2 = $sth2->fetchrow_hashref();
    $node->{"name"} = $res2->{"countDesc"} || $res->{"counter"};
    $sth2->finish();
    $sth2 = $DBH->prepare("select TKey1, TKey2, TKey3, TKey4, TKey5, TKey6, TKey7, TKey8, TKey9, TKey10, TKey11, TKey12, TKey13, TKey14, TKey15 from topo_def where TopId=?");
    @bindArr2 = ( $res->{"countTopId"} );
    $sth2->execute(@bindArr2) or die "Database error: ".$DBH->errstr; 
    $resTKey = $sth2->fetchrow_hashref();
    $sth2->finish();
    $sth2 = $DBH->prepare("select TKeyDesc1, TKeyDesc2, TKeyDesc3, TKeyDesc4, TKeyDesc5, TKeyDesc6, TKeyDesc7, TKeyDesc8, TKeyDesc9, TKeyDesc10, TKeyDesc11, TKeyDesc12, TKeyDesc13, TKeyDesc14, TKeyDesc15 from topo_desc where TopId=?");
    @bindArr2 = ( $res->{"countTopId"} );
    $sth2->execute(@bindArr2) or die "Database error: ".$DBH->errstr; 
    $resTKeyDesc = $sth2->fetchrow_hashref();
    $sth2->finish();
    $select = "";
    for ($j = $i; $j<=15; $j++) {
        last if ($resTKey->{"TKey$j"} eq "*"); 
        $select .= "Key$j".", "; 
    }
    $sth2 = $DBH->prepare("select $select DATE_FORMAT(DATE_ADD(meas_time, INTERVAL ? SECOND), '%Y-%m-%d %H:%i:%s') as mt, agg_type, val from $TBLNM use index ($TBLNM"."_ind".$indNum.") where $where and $COLNM=str_to_date(?, '%Y-%m-%d %H:%i:%s') and counter=? and countTopId=?");
    @bindArr2 = ( $cgi->param("GMTDiff") );
    push @bindArr2,$cgi->param("TopId");
    for ($k = 1; $k<$i; $k++) {
        push @bindArr2, $cgi->param("Key$k");
    }
    push @bindArr2, $cgi->param('GMTIME1');
    push @bindArr2, $res->{"counter"};
    push @bindArr2, $res->{"countTopId"};
    $sth2->execute(@bindArr2) or die "Database error: ".$DBH->errstr;
    $hashArr[$hashCnt] = [ ];
    $tbl1 = $hashArr[$hashCnt++];
    $hashArr[$hashCnt] = [ ];
    $tbl2 = $hashArr[$hashCnt++];
    $hashArr[$hashCnt] = [ ];
    $tbl3 = $hashArr[$hashCnt++];
    $sumFlag = $avgFlag = 0;
    while ($resMeas = $sth2->fetchrow_hashref()) {
        if ($resMeas->{"agg_type"} eq "sum") {
            $hashArr[$hashCnt] = [ ];
            $row = $hashArr[$hashCnt++];
            push @$row, "SUM";
            push @$row, $resMeas->{"val"};
            push @$tbl1, $row;
            $sumFlag = 1;
        } else {
            if ($resMeas->{"agg_type"} eq "avg") { 
                $hashArr[$hashCnt] = [ ];
                $row = $hashArr[$hashCnt++];
                push @$row, "AVG";
                push @$row, $resMeas->{"val"};
                push @$tbl1, $row;
                $avgFlag = 1;
            } else {
                if ($resMeas->{"agg_type"} =~ /^min/) {
                    $hashArr[$hashCnt] = [ ];
                    $row = $hashArr[$hashCnt++];
                    push @$row, $resMeas->{"agg_type"};
                    for ($k = $i; $k<$j; $k++) {
                        push @$row, $resMeas->{"Key$k"};
                    }
                    push @$row, $resMeas->{"mt"};
                    push @$row, $resMeas->{"val"};
                    push @$tbl2, $row;
                } else {
                    if ($resMeas->{"agg_type"} =~ /^max/) {
                        $hashArr[$hashCnt] = [ ];
                        $row = $hashArr[$hashCnt++];
                        push @$row, $resMeas->{"agg_type"};
                        for ($k = $i; $k<$j; $k++) {
                            push @$row, $resMeas->{"Key$k"};
                        }
                        push @$row, $resMeas->{"mt"};
                        push @$row, $resMeas->{"val"};
                        push @$tbl3, $row;
                    }
                }
            }
        }
    }
    $node->{"tbl1"} = $tbl1;
    $node->{"tbl2"} = [ ];
    @{$node->{"tbl2"}} = sort {return substr($a->[0], 3) <=> substr($b->[0], 3);} @$tbl2; 
    $node->{"tbl3"} = [ ];
    @{$node->{"tbl3"}} = sort {return substr($a->[0], 3) <=> substr($b->[0], 3);} @$tbl3; 
    $hashArr[$hashCnt] = [ ];
    $header = $hashArr[$hashCnt++];
    push @$header, "agg";
    for ($k = $i; $k<$j; $k++) {
        push @$header, ($resTKeyDesc->{"TKeyDesc$k"} || $resTKey->{"TKey$k"});
    }
    push @$header, "Time";
    push @$header, "Value";
    unshift @{$node->{"tbl2"}}, $header if (@{$node->{"tbl2"}});
    unshift @{$node->{"tbl3"}}, $header if (@{$node->{"tbl3"}});
    if (@{$node->{"tbl3"}} > 2) {
        $filename = "LSMpiechart$chartCnt.$$.png";
        $hashArr[$hashCnt] = [ ];
        $cd1 = $hashArr[$hashCnt++];
        $hashArr[$hashCnt] = [ ];
        $cd2 = $hashArr[$hashCnt++];
        $nonZeroFlag = 0;
        for ($k = 1; $k<@{$node->{"tbl3"}}; $k++) {
            push @$cd1, $node->{"tbl3"}->[$k]->[0];
            push @$cd2, $node->{"tbl3"}->[$k]->[@{$node->{"tbl3"}->[$k]} - 1];
            $nonZeroFlag = 1 if ($node->{"tbl3"}->[$k]->[@{$node->{"tbl3"}->[$k]} - 1] != 0);
        }
        if ($nonZeroFlag) {
            @chartData = ( $cd1, $cd2 );
            $chart = new GD::Graph::pie(200, 200);
            $chart->set( start_angle => 90, '3d' => 0, label => $node->{"name"}, transparent => 0 );
            $chart->plot(\@chartData) or die $chart->error;
            open(IMG, ">$ROOTDIR/$filename") or die $!;
            binmode IMG;
            print IMG $chart->gd->png();
            close(IMG);
            $node->{"piechart"} = $filename;
            $chartCnt++;
        }
    }
    if ($sumFlag && defined($TBLNM2)) {
        $sth2 = $DBH->prepare("select DATE_FORMAT(DATE_ADD($COLNM2, INTERVAL ? SECOND), '".$dtFormat."') as dt, val from $TBLNM2 use index ($TBLNM2"."_ind".$indNum.") where $where and $COLNM2 between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s') and counter=? and countTopId=? and agg_type='sum' order by $COLNM2");
        @bindArr2 = ( $cgi->param("GMTDiff") );
        push @bindArr2, $cgi->param("TopId");
        for ($k = 1; $k<$i; $k++) {
            push @bindArr2, $cgi->param("Key$k");
        }
        push @bindArr2, $cgi->param('GMTIME1');
        push @bindArr2, $cgi->param('GMTIME2');
        push @bindArr2, $res->{"counter"};
        push @bindArr2, $res->{"countTopId"};
        $sth2->execute(@bindArr2) or die "Database error: ".$DBH->errstr;
        $filename = "LSMbarchartSUM$chartCnt.$$.png";
        $hashArr[$hashCnt] = [ ];
        $cd1 = $hashArr[$hashCnt++];
        $hashArr[$hashCnt] = [ ];
        $cd2 = $hashArr[$hashCnt++];
        while ($res2 = $sth2->fetchrow_hashref()) {
            push @$cd1, $res2->{"dt"};
            push @$cd2, $res2->{"val"};
        }
        @chartData = ( $cd1, $cd2 );
        $gdData = GD::Graph::Data->new( [$cd1, $cd2] ) or die GD::Graph::Data->error;
        $chart = new GD::Graph::bars();
        $chart->set( x_label => $xLabel, y_label => 'values', title => "Sums for ".$node->{"name"},
                     bar_spacing => 8, shadow_depth => 4, shadowclr => 'dred', transparent => 0 );
        if (@$cd1) {
            $chart->plot($gdData) or die $chart->error;
            open(IMG, ">$ROOTDIR/$filename") or die $!;
            binmode IMG;
            print IMG $chart->gd->png();
            close(IMG);
            $node->{"barchartSum"} = $filename;
            $chartCnt++;
        }
    }
    if ($avgFlag && defined($TBLNM2)) {
        $sth2 = $DBH->prepare("select DATE_FORMAT(DATE_ADD($COLNM2, INTERVAL ? SECOND),'".$dtFormat."') as dt, val from $TBLNM2 use index ($TBLNM2"."_ind".$indNum.") where $where and $COLNM2 between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s') and counter=? and countTopId=? and agg_type='avg' order by $COLNM2");
        @bindArr2 = ( $cgi->param("GMTDiff") );
        push @bindArr2, $cgi->param("TopId");
        for ($k = 1; $k<$i; $k++) {
            push @bindArr2, $cgi->param("Key$k");
        }
        push @bindArr2, $cgi->param('GMTIME1');
        push @bindArr2, $cgi->param('GMTIME2');
        push @bindArr2, $res->{"counter"};
        push @bindArr2, $res->{"countTopId"};
        $sth2->execute(@bindArr2) or die "Database error: ".$DBH->errstr;
        $filename = "LSMbarchartAVG$chartCnt.$$.png";
        $hashArr[$hashCnt] = [ ];
        $cd1 = $hashArr[$hashCnt++];
        $hashArr[$hashCnt] = [ ];
        $cd2 = $hashArr[$hashCnt++];
        while ($res2 = $sth2->fetchrow_hashref()) {
            push @$cd1, $res2->{"dt"};
            push @$cd2, $res2->{"val"};
        }
        @chartData = ( $cd1, $cd2 );
        $gdData = GD::Graph::Data->new( [$cd1, $cd2] ) or die GD::Graph::Data->error;
        $chart = new GD::Graph::bars();
        $chart->set( x_label => $xLabel, y_label => 'values', title => "Averages for ".$node->{"name"},
                     bar_spacing => 8, shadow_depth => 4, shadowclr => 'dred', transparent => 0 );
        if (@$cd1) {
            $chart->plot($gdData) or die $chart->error;
            open(IMG, ">$ROOTDIR/$filename") or die $!;
            binmode IMG;
            print IMG $chart->gd->png();
            close(IMG);
            $node->{"barchartAvg"} = $filename;
            $chartCnt++;
       }
    }
    push @$counters, $node;
}

my $crit = [ ];
for ($k = 1; $k<$i; $k++) {
    $hashArr[$hashCnt] = [ ];
    $row = $hashArr[$hashCnt++];
    push @$row, ($resTKeyDesc->{"TKeyDesc$k"} || $resTKey->{"TKey$k"});
    push @$row, $cgi->param("Key$k");
    push @$crit, $row;
}

$vars->{"period"} = $period;
$vars->{"counters"} = $counters;
$vars->{"criteria"} = $crit;

$tt->process($template, $vars)
    || die $tt->error(  );

$DBH->disconnect();
 
