# Class : dbAgg
# Description : This class implements a database aggregator
# v.1.0, 11/1/2009, Dan Graham

package dbAgg;
use DBI;
use Data::Dumper;
use Time::Local;
use Config;
use strict;

sub new {
    my $class = shift;
    my $args = shift;
    my $self = { };
    $self->{"host"} = $args->{"host"};
    $self->{"dbname"} = $args->{"dbname"}; 
    $self->{"user"} = $args->{"user"};
    $self->{"password"} = $args->{"password"};
    $self->{"aggHourInt"} = $args->{"aggHourInt"} || 5*60;
    $self->{"aggDayInt"} = $args->{"aggDayInt"} || 10*60;
    $self->{"aggWeekInt"} = $args->{"aggWeekInt"} || 15*60;
    $self->{"aggMonthInt"} = $args->{"aggMonthInt"} || 20*60;
    return bless($self, $class);
}

sub connect {
    my $self = shift;
    $self->{"dbh"} = DBI->connect("DBI:mysql:$self->{'dbname'};host=$self->{'host'}", $self->{"user"}, $self->{"password"} 
	           ) || $self->logmsg("Could not connect to database: $DBI::errstr \n");
    return;
}

sub disconnect {
    my $self = shift;
    $self->{"dbh"}->disconnect();
    return;
}

sub start {
    my $self = shift;
    my $server = shift;
    $self->{"topidIgnore"} = { };
    open(INFILE, "topid.ignore");
    foreach my $x (<INFILE>) {
        chomp($x);
        $self->{"topidIgnore"}->{"$x"} = 1;
    }
    close(INFILE); 
    $self->{"server"} = $server;
    $self->startHourly();
    $self->startDaily();
    $self->startWeekly();
    $self->startMonthly();
}

sub startHourly {
    my $self = shift;
    my $pid1;
    if (defined($self->{"pid1"})) {
        $self->logmsg("error: dbAgg Hourly already started - stop dbAgg Hourly first");
        return;
    }
    if (!defined($pid1 = fork)) {
        $self->logmsg("Error: cannot fork: $!");
        return;
    } elsif ($pid1) {
        $self->logmsg("starting dbAgg Hourly with pid $pid1");
        $self->{"pid1"} = $pid1; 
        return;
    }
    local $SIG{'TERM'} = sub {
        $self->logmsg("stopping dbAgg Hourly...");
        $self->{"pid1"} = undef;
        exit(0);
    };
    while (1) {
        eval {$self->compute('hourly')};
        if ($@) {
            $self->logmsg("Error on hourly [$@]");
            $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        }
        sleep $self->{"aggHourInt"};
   }
}

sub startDaily {
    my $self = shift;
    my $pid2;
    if (defined($self->{"pid2"})) {
        $self->logmsg("error: dbAgg Daily already started - stop dbAgg Daily first");
        return;
    }
    if (!defined($pid2 = fork)) {
        $self->logmsg("Error: cannot fork: $!");
        return;
    } elsif ($pid2) {
        $self->logmsg("starting dbAgg Daily with pid $pid2");
        $self->{"pid2"} = $pid2; 
        return;
    }
    local $SIG{'TERM'} = sub {
        $self->logmsg("stopping dbAgg Daily...");
        $self->{"pid2"} = undef;
        exit(0);
    };
    while (1) {
        sleep 1;
        eval {$self->compute('daily')};
        if ($@) {
            $self->logmsg("Error on daily [$@]");
            $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        }
        sleep $self->{"aggDayInt"};
   }
}

sub startWeekly {
    my $self = shift;
    my $pid3;
    if (defined($self->{"pid3"})) {
        $self->logmsg("error: dbAgg Weekly already started - stop dbAgg Weekly first");
        return;
    }
    if (!defined($pid3 = fork)) {
        $self->logmsg("Error: cannot fork: $!");
        return;
    } elsif ($pid3) {
        $self->logmsg("starting dbAgg Weekly with pid $pid3");
        $self->{"pid3"} = $pid3; 
        return;
    }
    local $SIG{'TERM'} = sub {
        $self->logmsg("stopping dbAgg Weekly...");
        $self->{"pid3"} = undef;
        exit(0);
    };
    while (1) {
        sleep 2;
        eval {$self->compute('weekly')};
        if ($@) {
            $self->logmsg("Error on weekly [$@]");
            $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        }
        sleep $self->{"aggWeekInt"};
   }
}

sub startMonthly {
    my $self = shift;
    my $pid4;
    if (defined($self->{"pid4"})) {
        $self->logmsg("error: dbAgg Monthly already started - stop dbAgg Monthly first");
        return;
    }
    if (!defined($pid4 = fork)) {
        $self->logmsg("Error: cannot fork: $!");
        return;
    } elsif ($pid4) {
        $self->logmsg("starting dbAgg Monthly with pid $pid4");
        $self->{"pid4"} = $pid4; 
        return;
    }
    local $SIG{'TERM'} = sub {
        $self->logmsg("stopping dbAgg Monthly...");
        $self->{"pid4"} = undef;
        exit(0);
    };
    while (1) {
        sleep 3;
        eval {$self->compute('monthly')};
        if ($@) {
            $self->logmsg("Error on monthly [$@]");
            $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        }
        sleep $self->{"aggMonthInt"};
   }
}

sub stop {
    my $self = shift;
    my (%signo, @signame);
    my $i = 0;
    foreach my $name (split(' ', $Config{sig_name})) {
        $signo{$name} = $i;
        $signame[$i] = $name;
        $i++;
    }
    for (my $n = 1; $n <= 4; $n++) {
        if (!defined($self->{"pid$n"})) {
            next;
        }
        if (kill($signo{TERM}, $self->{"pid$n"}) < 1) {
            $self->logmsg("error: could not stop ".$self->{"pid$n"});
        }
    }
}

sub compute {
    my $self = shift;
    my $period = shift;
    $self->{"server"}->{"sem2"}->op(0, -1, 0) or $self->logmsg("Semaphore error: $!");
    $self->logmsg("Start aggregation period=$period");
    $self->connect();
    $self->{"dbh"}->begin_work();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    $year += 1900;
    $mon++;
    my ($sumTime1, $sumTime2, $sumTime1Prev, $sumTime2Prev);
    my ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2); 
    $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, "00", "00") if ($period eq "hourly");
    $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, "00", "00", "00") if ($period eq "daily");
    $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, "59", "59") if ($period eq "hourly");
    $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, "23", "59", "59") if ($period eq "daily");
    if ($period eq "monthly") {
        $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, "01", "00", "00", "00");
        if ($mon == 12) {
            $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1, "01", "01", "00", "00", "00");
        } else {
            $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon + 1, "01", "00", "00", "00");
        }
    }
    if ($period eq "weekly") {
        ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2) = gmtime(time - ($hour * 60 * 60 + $min * 60 + $sec) - ($wday * 24 * 60 * 60));
        $year2 += 1900;
        $mon2++;
        $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year2, $mon2, $mday2, $hour2, $min2, $sec2);
        ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2) = gmtime(time - ($hour * 60 * 60 + $min * 60 + $sec) - ($wday * 24 * 60 * 60) + (7 * 24 * 60 * 60));
        $year2 += 1900;
        $mon2++;
        $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year2, $mon2, $mday2, $hour2, $min2, $sec2);
    }
    if ($self->computeWithTime($period, $sumTime1, $sumTime2) < 0) {
        $self->disconnect();
        $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        $self->logmsg("End aggregation period=$period");
        return(-1);
    }
    $self->{"dbh"}->commit();
    $self->{"dbh"}->begin_work();
## process historicals
    my ($sth, $rv, $res, $epochTime, $colNm);
    if ($period eq "hourly") {
        $colNm = "agg_hour";
    } else {
        if ($period eq "daily") {
            $colNm = "agg_day";
        } else {
            if ($period eq "weekly") {
                $colNm = "agg_week";
            } else {
                if ($period eq "monthly") {
                    $colNm = "agg_month";
                }
            }
        }
    }
    $sth = $self->{"dbh"}->prepare("update meas_vals set $colNm=1 where meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
    my @bindArg =  ($sumTime1, $sumTime2);
    $rv = $sth->execute(@bindArg);
    if (!defined($rv)) {
        $self->logmsg("Could not execute update (".__LINE__."): ".$self->{"dbh"}->errstr." \n");
        $self->{"dbh"}->rollback();
        $self->disconnect();
        $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        $self->logmsg("End aggregation period=$period");
        return(-1);
    }
    $self->{"dbh"}->commit();
    my $sthz = $self->{"dbh"}->prepare("select distinct(DATE_FORMAT(meas_time, '%Y-%m-%d %H:%i:%s')) as dt from meas_vals where ($colNm is null) or ($colNm=0)");
    $rv = $sthz->execute();
    if (!defined($rv)) {
        $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
        $self->{"dbh"}->rollback();
        $self->disconnect();
        $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        $self->logmsg("End aggregation period=$period");
        return(-1);
    }
    while ($res = $sthz->fetchrow_hashref()) {
        ($year, $mon, $mday, $hour, $min, $sec) = split(/[\- \:]/, $res->{"dt"});
        $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, "00", "00") if ($period eq "hourly");
        $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, "00", "00", "00") if ($period eq "daily");
        $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, "59", "59") if ($period eq "hourly");
        $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, "23", "59", "59") if ($period eq "daily");
        if ($period eq "monthly") {
            $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, "01", "00", "00", "00");
            if ($mon == 12) {
                $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1, "01", "01", "00", "00", "00");
            } else {
                $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon + 1, "01", "00", "00", "00");
            }
        }
        if ($period eq "weekly") {
            $epochTime = timegm($sec, $min, $hour, $mday, $mon - 1, $year);
            ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime($epochTime);
            ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2) = gmtime($epochTime - ($hour * 60 * 60 + $min * 60 + $sec) - ($wday * 24 * 60 * 60));
            $year2 += 1900;
            $mon2++;
            $sumTime1 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year2, $mon2, $mday2, $hour2, $min2, $sec2);
            ($sec2,$min2,$hour2,$mday2,$mon2,$year2,$wday2,$yday2,$isdst2) = gmtime($epochTime - ($hour * 60 * 60 + $min * 60 + $sec) - ($wday * 24 * 60 * 60) + (7 * 24 * 60 * 60));
            $year2 += 1900;
            $mon2++;
            $sumTime2 = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year2, $mon2, $mday2, $hour2, $min2, $sec2);
        }
        next if (($sumTime1 eq $sumTime1Prev) && ($sumTime2 eq $sumTime2Prev));
        $sumTime1Prev = $sumTime1;
        $sumTime2Prev = $sumTime2;
        $self->{"dbh"}->begin_work();
        if ($self->computeWithTime($period, $sumTime1, $sumTime2) < 0) {
            $self->disconnect();
            $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
            $self->logmsg("End aggregation period=$period");
            return(-1);
        }
        $sth = $self->{"dbh"}->prepare("update meas_vals set $colNm=1 where meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
        @bindArg =  ($sumTime1, $sumTime2);
        $rv = $sth->execute(@bindArg);
        if (!defined($rv)) {
            $self->logmsg("Could not execute update (".__LINE__."): ".$self->{"dbh"}->errstr." \n");
            $self->{"dbh"}->rollback();
            $self->disconnect();
            $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
            $self->logmsg("End aggregation period=$period");
            return(-1);
        }
        $self->{"dbh"}->commit();
    }
    if (!defined($res) && $sthz->err) {
        $self->logmsg("Could not execute fetchrow_hashref: (".__LINE__.") ".$self->{"dbh"}->errstr."\n");
        $self->{"dbh"}->rollback();
        $self->disconnect();
        $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
        $self->logmsg("End aggregation period=$period");
        return(-1);
    }
    $self->disconnect();
    $self->{"server"}->{"sem2"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!");
    $self->logmsg("End aggregation period=$period");
    return(0);
} 

sub computeWithTime {
    my $self = shift;
    my $period = shift;
    my $sumTime1 = shift;
    my $sumTime2 = shift;
    my %colNmHash = ( 'hourly' => 'agg_hour', 'daily' => 'agg_day', 'weekly' => 'agg_week', 'monthly' => 'agg_month' );
    my $colNm = $colNmHash{"$period"};
    my $sth = $self->{"dbh"}->prepare("select distinct TopId from meas_vals where meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s') and (($colNm is null) or ($colNm=0))");
    my @bindArg = ( $sumTime1, $sumTime2 );
    my $rv = $sth->execute(@bindArg);
    if (!defined($rv)) {
        $self->logmsg("Could not execute query (".__LINE__."): ".$self->{"dbh"}->errstr." \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    my $topIds = $sth->fetchall_arrayref({});
    my ($topId, $n, $res, @callStack, $cs, $where, $i, $x, @hashArr, $subTopId);
    my $hashCnt = 0;
    foreach my $t (@$topIds) {
        $topId = $t->{"TopId"};
        $sth = $self->{"dbh"}->prepare("select TKey1, TKey2, TKey3, TKey4, TKey5, TKey6, TKey7, TKey8, TKey9, TKey10, TKey11, TKey12, TKey13, TKey14, TKey15 from topo_def where TopId=?");
        @bindArg = ( $topId );
        $rv = $sth->execute(@bindArg);
        if (!defined($rv)) {
            $self->logmsg("Could not execute query (".__LINE__."): ".$self->{"dbh"}->errstr." \n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
        $res = $sth->fetchrow_hashref();
        for ($n = 2; $n<=15; $n++) {
            last if ($res->{"TKey$n"} eq "*");
        }
        $subTopId = $self->getSubTopIds($res, $n);
        if (!defined($subTopId)) {
            return(-1);
        }
        @callStack = ( ["*"] );
        while (@callStack) {
            $where = "";
            $cs = pop @callStack;
            for ($i = 1; $i<=@$cs; $i++) {
                $where .= " and Key$i"."='".$cs->[$i-1]."'";
            } 
            if (!defined($self->{"topidIgnore"}->{$subTopId->[@$cs - 1]})) {
                return(-1) if ($self->process($period, $topId, $sumTime1, $sumTime2, $where, $subTopId->[@$cs - 1], $i-1) < 0);
            }
            if ($i < $n) { 
                $sth = $self->{"dbh"}->prepare("select distinct Key$i from meas_vals use index (meas_vals_ind".($i+5).") where TopId=?".$where." and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
                @bindArg = ( $topId, $sumTime1, $sumTime2 ); 
                $rv = $sth->execute(@bindArg);
                if (!defined($rv)) {
                    $self->logmsg("Could not execute query (".__LINE__."): ".$self->{"dbh"}->errstr." \n");
                    $self->{"dbh"}->rollback();
                    return(-1);
                }
                while ($res = $sth->fetchrow_hashref()) {
                    $x = $res->{"Key$i"};
                    $hashArr[$hashCnt] = [ ];
                    foreach (@$cs) {
                        push @{$hashArr[$hashCnt]}, $_;
                    }
                    push @{$hashArr[$hashCnt]}, $x;
                    push @callStack, $hashArr[$hashCnt++];
                }
            }
        }
    }
    return(0);
}
                 
sub process {
    my $self = shift;
    my $period = shift;
    my $topId = shift;
    my $sumTime1 = shift;
    my $sumTime2 = shift;
    my $where = shift;
    my $topIdAgg = shift;
    my $indNum = shift;
    my $sth = $self->{"dbh"}->prepare("select distinct counter from meas_vals use index (meas_vals_ind".($indNum + 5).") where TopId=?".$where." and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
    my @bindArg = ( $topId, $sumTime1, $sumTime2 );
    my $rv = $sth->execute(@bindArg);
    if (!defined($rv)) {
        $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    my $counters = $sth->fetchall_arrayref({});
    my ($counter, $res, $res2, $res3, $whereHash, $i, $j, $sth2, @bindArg2, %seenBefore, $concatVal);
    foreach my $c (@$counters) {
        $counter = $c->{"counter"};
        $sth = $self->{"dbh"}->prepare("select sumA, avgA, minA, maxA from meas_types where TopId=? and counter=?");
        @bindArg = ( $topId, $counter );
        $rv = $sth->execute(@bindArg);
        if (!defined($rv)) {
            $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
        $res = $sth->fetchrow_hashref();
        if ($res->{"sumA"}) {
            $sth = $self->{"dbh"}->prepare("select sum(val) as sumA from meas_vals use index (meas_vals_ind".($indNum + 5).") where TopId=?".$where." and counter=? and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
            @bindArg = ( $topId, $counter, $sumTime1, $sumTime2 );
            $rv = $sth->execute(@bindArg);
            if (!defined($rv)) {
                $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
                $self->{"dbh"}->rollback();
                return(-1);
            }
            $res2 = $sth->fetchrow_hashref();
            $whereHash = $self->convertWhere($where);
#            $self->logmsg("Start upsert: $period, $topIdAgg, $where, \"\", $counter, $sumTime1, \"sum\", $res2->{'sumA'}");
            return(-1) if ($self->upsert($period, $topIdAgg, $where, $whereHash, "", $counter, $sumTime1, "sum", $res2->{"sumA"}, $topId, $indNum) < 0);
        } 
        if ($res->{"avgA"}) {
            $sth = $self->{"dbh"}->prepare("select avg(val) as avgA from meas_vals use index (meas_vals_ind".($indNum + 5).") where TopId=?".$where." and counter=? and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
            @bindArg = ( $topId, $counter, $sumTime1, $sumTime2 );
            $rv = $sth->execute(@bindArg);
            if (!defined($rv)) {
                $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
                $self->{"dbh"}->rollback();
                return(-1);
            }
            $res2 = $sth->fetchrow_hashref();
            $whereHash = $self->convertWhere($where);
#            $self->logmsg("Start upsert: $period, $topIdAgg, $where, \"\", $counter, $sumTime1, \"avg\", $res2->{'avgA'}");
            return(-1) if ($self->upsert($period, $topIdAgg, $where, $whereHash, "", $counter, $sumTime1, "avg", $res2->{"avgA"}, $topId, $indNum) < 0);
        } 
        if ($res->{"minA"}) {
            $sth = $self->{"dbh"}->prepare("select distinct Key1, Key2, Key3, Key4, Key5, Key6, Key7, Key8, Key9, Key10, Key11, Key12, Key13, Key14, Key15, meas_time, val from meas_vals use index (meas_vals_ind20) where TopId=?".$where." and counter=? and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s') order by val asc, meas_time desc");
            @bindArg = ( $topId, $counter, $sumTime1, $sumTime2 );
            $rv = $sth->execute(@bindArg);
            if (!defined($rv)) {
                $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
                $self->{"dbh"}->rollback();
                return(-1);
            }
            %seenBefore = ( );
            $i = 1;
            while($i <= 10) { 
                $res2 = $sth->fetchrow_hashref();
                last if (!defined($res2));
                $concatVal = $res2->{"Key1"}.$res2->{"Key2"}.$res2->{"Key3"}.$res2->{"Key4"}.$res2->{"Key5"}.$res2->{"Key6"}.$res2->{"Key7"}.$res2->{"Key8"}.$res2->{"Key9"}.$res2->{"Key10"}.$res2->{"Key11"}.$res2->{"Key12"}.$res2->{"Key13"}.$res2->{"Key14"}.$res2->{"Key15"};
                next if (defined($seenBefore{"$concatVal"}));
                $seenBefore{"$concatVal"} = 1;
                $whereHash = { 'Key1' => $res2->{"Key1"},
                               'Key2' => $res2->{"Key2"},
                               'Key3' => $res2->{"Key3"},
                               'Key4' => $res2->{"Key4"},
                               'Key5' => $res2->{"Key5"},
                               'Key6' => $res2->{"Key6"},
                               'Key7' => $res2->{"Key7"},
                               'Key8' => $res2->{"Key8"},
                               'Key9' => $res2->{"Key9"},
                               'Key10' => $res2->{"Key10"},
                               'Key11' => $res2->{"Key11"},
                               'Key12' => $res2->{"Key12"},
                               'Key13' => $res2->{"Key13"},
                               'Key14' => $res2->{"Key14"},
                               'Key15' => $res2->{"Key15"}
                             };
#                $sth2 = $self->{"dbh"}->prepare("select max(DATE_FORMAT(meas_time, '%Y-%m-%d %H:%i:%s')) as mt from meas_vals use index (meas_vals_ind".($indNum + 5).") where val=? and TopId=?".$where." and counter=? and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
#                @bindArg2 = ( );
#                push @bindArg2, $res2->{"val"};
#                push @bindArg2, $topId;
#                push @bindArg2, $counter;
#                push @bindArg2, $sumTime1;
#                push @bindArg2, $sumTime2; 
#                $rv = $sth2->execute(@bindArg2);
#                if (!defined($rv)) {
#                    $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
#                    $self->{"dbh"}->rollback();
#                    return(-1);
#                }
#                $res3 = $sth2->fetchrow_hashref();
#                $self->logmsg("Start upsert: $period, $topIdAgg, $where, $res3->{'mt'}, $counter, $sumTime1, \"min$i\", $res2->{'val'}");
                return(-1) if ($self->upsert($period, $topIdAgg, $where, $whereHash, $res2->{"meas_time"}, $counter, $sumTime1, "min$i", $res2->{"val"}, $topId, $indNum) < 0);
            $i++;
            }
        }
        if ($res->{"maxA"}) {
            $sth = $self->{"dbh"}->prepare("select distinct Key1, Key2, Key3, Key4, Key5, Key6, Key7, Key8, Key9, Key10, Key11, Key12, Key13, Key14, Key15, meas_time, val from meas_vals use index (meas_vals_ind20) where TopId=?".$where." and counter=? and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s') order by val desc, meas_time desc");
            @bindArg = ( $topId, $counter, $sumTime1, $sumTime2 );
            $rv = $sth->execute(@bindArg);
            if (!defined($rv)) {
                $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
                $self->{"dbh"}->rollback();
                return(-1);
            }
            %seenBefore = ( );
            $i = 1;
            while($i <= 10) { 
                $res2 = $sth->fetchrow_hashref();
                last if (!defined($res2));
                $concatVal = $res2->{"Key1"}.$res2->{"Key2"}.$res2->{"Key3"}.$res2->{"Key4"}.$res2->{"Key5"}.$res2->{"Key6"}.$res2->{"Key7"}.$res2->{"Key8"}.$res2->{"Key9"}.$res2->{"Key10"}.$res2->{"Key11"}.$res2->{"Key12"}.$res2->{"Key13"}.$res2->{"Key14"}.$res2->{"Key15"};
                next if (defined($seenBefore{"$concatVal"}));
                $seenBefore{"$concatVal"} = 1;
                $whereHash = { 'Key1' => $res2->{"Key1"},
                               'Key2' => $res2->{"Key2"},
                               'Key3' => $res2->{"Key3"},
                               'Key4' => $res2->{"Key4"},
                               'Key5' => $res2->{"Key5"},
                               'Key6' => $res2->{"Key6"},
                               'Key7' => $res2->{"Key7"},
                               'Key8' => $res2->{"Key8"},
                               'Key9' => $res2->{"Key9"},
                               'Key10' => $res2->{"Key10"},
                               'Key11' => $res2->{"Key11"},
                               'Key12' => $res2->{"Key12"},
                               'Key13' => $res2->{"Key13"},
                               'Key14' => $res2->{"Key14"},
                               'Key15' => $res2->{"Key15"}
                             };
#                $sth2 = $self->{"dbh"}->prepare("select max(DATE_FORMAT(meas_time, '%Y-%m-%d %H:%i:%s')) as mt from meas_vals use index (meas_vals_ind".($indNum + 5).") where val=? and TopId=?".$where." and counter=? and meas_time between str_to_date(?, '%Y-%m-%d %H:%i:%s') and str_to_date(?, '%Y-%m-%d %H:%i:%s')");
#                @bindArg2 = ( );
#                push @bindArg2, $res2->{"val"};
#                push @bindArg2, $topId;
#                push @bindArg2, $counter;
#                push @bindArg2, $sumTime1;
#                push @bindArg2, $sumTime2; 
#                $rv = $sth2->execute(@bindArg2);
#                if (!defined($rv)) {
#                    $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
#                    $self->{"dbh"}->rollback();
#                    return(-1);
#                }
#                $res3 = $sth2->fetchrow_hashref();
#                $self->logmsg("Start upsert: $period, $topIdAgg, $where, $res3->{'mt'}, $counter, $sumTime1, \"max$i\", $res2->{'val'}");
                return(-1) if ($self->upsert($period, $topIdAgg, $where, $whereHash, $res2->{"meas_time"}, $counter, $sumTime1, "max$i", $res2->{"val"}, $topId, $indNum) < 0);
            $i++;
            }
        }
    }
    return(0);
}

sub convertWhere {
    my $self = shift;
    my $where = shift;
    my $ret = { };
    $where =~ s/^ and //g;
    %{$ret} = split(/ and |\=/, $where);
    foreach my $k (keys %{$ret}) {
        $ret->{"$k"} =~ s/^\'(.*)\'$/$1/g;
    }
    for (my $i = 1; $i <= 15; $i++) {
        if (!defined($ret->{"Key$i"})) {
            $ret->{"Key$i"} = "*";
        }
    }
    return($ret);
}

sub upsert {
    my $self = shift;
    my $period = shift;
    my $topId = shift;
    my $where = shift;
    my $whereHash = shift;
    my $measTime = shift;
    my $counter = shift;
    my $aggTime = shift;
    my $aggType = shift;
    my $aggVal = shift;
    my $countTopId = shift;
    my $indNum = shift;
    my ($tableNm, $colNm);
    if ($period eq "hourly") {
        $tableNm = "hourly_agg";
        $colNm = "time_hour";
    } else {
        if ($period eq "daily") {
            $tableNm = "daily_agg";
            $colNm = "time_day";
        } else {
            if ($period eq "weekly") {
                $tableNm = "weekly_agg";
                $colNm = "time_week";
            } else {
                if ($period eq "monthly") {
                    $tableNm = "monthly_agg";
                    $colNm = "time_month";
                }
            }
        }
    }
    my $selectClause = "";
    foreach my $k (keys %$whereHash) {
        $selectClause .= $k.", ";
    }
    $selectClause .= "DATE_FORMAT(meas_time, '%Y-%m-%d %H:%i:%s') as dt, val";
    my $sth = $self->{"dbh"}->prepare("select $selectClause from $tableNm use index ($tableNm"."_ind".$indNum.") where TopId=?".$where." and counter=? and $colNm=str_to_date(?, '%Y-%m-%d %H:%i:%s') and agg_type=? and countTopId=?");
    my @bindArg = ( $topId, $counter, $aggTime, $aggType, $countTopId );
    my $rv = $sth->execute(@bindArg);
    if (!defined($rv)) {
        $self->logmsg("Could not execute query: (".__LINE__.") ".$self->{"dbh"}->errstr." \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    my $res = $sth->fetchrow_hashref();
    my ($insertParam, $insertVals, @insertVals, $setClause, $stmt, $k);
    if (!defined($res) && !$sth->err) {
#        $self->logmsg("Starting insert on $tableNm, $counter [$where]");
        $insertParam = "( ";
        $insertVals = "( ";
        foreach $k (keys %$whereHash) {
            $insertParam .= "$k, ";
            $insertVals .= "?, ";
            push @insertVals, $whereHash->{"$k"};
        }
        $stmt = "insert into $tableNm ".$insertParam." TopId, meas_time, counter, $colNm, agg_type, val, countTopId) values ".$insertVals." ?, str_to_date(?, '%Y-%m-%d %H:%i:%s'), ?, str_to_date(?, '%Y-%m-%d %H:%i:%s'), ?, ?, ?)";
        $sth = $self->{"dbh"}->prepare($stmt);
        @bindArg = @insertVals;
        push @bindArg, $topId;
        push @bindArg, $measTime;
        push @bindArg, $counter;
        push @bindArg, $aggTime;
        push @bindArg, $aggType;
        push @bindArg, $aggVal;
        push @bindArg, $countTopId;
        $rv = $sth->execute(@bindArg);
        if (!defined($rv)) {
            $self->logmsg("Could not execute insert: ".__LINE__." ".$self->{"dbh"}->errstr." [$stmt]\n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
    } else {
#        $self->logmsg("Starting update on $tableNm, $counter [$where]");
        my $equal = 1;
        my $nMeasTime = ($measTime =~ /\d.*/) ? $measTime:"0000-00-00 00:00:00";
        my $nAggVal = sprintf("%8.4f", int(($aggVal * 10000) + .5 * ($aggVal <=> 0))/10000);
        foreach my $k (keys %$whereHash) {
            if ($res->{$k} ne $whereHash->{"$k"}) {
                $equal = 0;
            }
        } 
        if ($res->{"dt"} ne $nMeasTime) {
            $equal = 0;
        }
        if ($res->{"val"} != $nAggVal) {
            $equal = 0;
        }
        if (!$equal) {
            $setClause = "";
            foreach my $k (keys %$whereHash) {
                $setClause .= $k."=?,";
                push @insertVals, $whereHash->{"$k"};
            }
            $setClause .= " meas_time=?, val=? ";
            $stmt = "update $tableNm set ".$setClause." where TopId=?".$where." and counter=? and $colNm=str_to_date(?, '%Y-%m-%d %H:%i:%s') and agg_type=? and countTopId=?";
            $sth = $self->{"dbh"}->prepare($stmt);
            @bindArg = @insertVals;
            push @bindArg, $measTime;
            push @bindArg, $aggVal;
            push @bindArg, $topId;
            push @bindArg, $counter;
            push @bindArg, $aggTime;
            push @bindArg, $aggType;
            push @bindArg, $countTopId;
            $rv = $sth->execute(@bindArg);
            if (!defined($rv)) {
                $self->logmsg("Could not execute update (".__LINE__.") ".$self->{"dbh"}->errstr."[$stmt]\n");
                $self->{"dbh"}->rollback();
                return(-1);
            }
        }
    }
    return(0);
}

sub getSubTopIds {
    my $self = shift;
    my $res = shift;
    my $n = shift;
    my $ret = [ ];
    my ($stmt, $sth, @bindArg, $j, $k, $rv, $res2);
    $stmt = "select TopId from topo_def where TKey1=? and TKey2=? and TKey3=? and TKey4=? and TKey5=? and TKey6=? and TKey7=? and TKey8=? and TKey9=? and TKey10=? and TKey11=? and TKey12=? and TKey13=? and TKey14=? and TKey15=?";
    for (my $i = 1; $i<$n; $i++) {
        @bindArg = ( );
        $sth = $self->{"dbh"}->prepare($stmt);
        for ($j = 1; $j<=$i; $j++) {
            push @bindArg, $res->{"TKey$j"};
        }
        for ($k = $j; $k<=15; $k++) {
            push @bindArg, "*";
        }
        $rv = $sth->execute(@bindArg);
        if (!defined($rv)) {
            $self->logmsg("Could not execute select (".__LINE__."( ".$self->{"dbh"}->errstr." [$stmt]\n");
            $self->{"dbh"}->rollback();
            return(undef);
        }
        $res2 = $sth->fetchrow_hashref();
        $ret->[$i-1] = $res2->{"TopId"};
    }
    return $ret;
} 

sub logmsg {
    my $self = $_[0];
    my $msg = $_[1];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon++;
    my $logTime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
    open(OUTFILE, ">>/tmp/LSMserver.log");
    print OUTFILE $logTime." ==> ".$msg."\n";
    close(OUTFILE);
    return;
}
    
1;
