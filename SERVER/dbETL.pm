# Class : dbETL
# Desc  : This class implements a database ETL loader
# v.1.0, 10/21/2009, Dan Graham

package dbETL;
use DBI;
use Data::Dumper;
use strict;

sub new {
    my $class = shift;
    my $args = shift;
    my $self = { };
    $self->{"host"} = $args->{"host"};
    $self->{"dbname"} = $args->{"dbname"}; 
    $self->{"user"} = $args->{"user"};
    $self->{"password"} = $args->{"password"};
    $self->{"port"} = $args->{"dbport"};
    return bless($self, $class);
}

sub connect {
    my $self = shift;
    $self->{"dbh"} = DBI->connect("DBI:mysql:$self->{'dbname'};host=$self->{'host'};port=$self->{'port'}", $self->{"user"}, $self->{"password"} 
	           ) || $self->logmsg("Could not connect to database: $DBI::errstr \n");
    return;
}

sub disconnect {
    my $self = shift;
    $self->{"dbh"}->disconnect();
    return;
}

sub updateTbls {
    my $self = shift;
    my $dbData = shift;
    my (@topoArr, $t, $topoId);
    $self->{"dbh"}->begin_work();
    foreach $t (@{$dbData->{"topo"}}) {
        push @topoArr, $t;
        return if (($topoId = $self->registerTopo(\@topoArr)) < 0);
    }
    return if ($self->registerCount($dbData, $topoId) < 0);
    my $sth = $self->{"dbh"}->prepare("select val from meas_vals use index (meas_vals_ind20) where TopId=? and Key1=? and Key2=? and Key3=? and Key4=? and Key5=? and Key6=? and Key7=? and Key8=? and Key9=? and Key10=? and Key11=? and Key12=? and Key13=? and Key14=? and Key15=? and counter=? and meas_time=str_to_date(?, '%Y-%m-%d %H:%i:%s')");
    my (@bindArg, @bindArg2);
    push @bindArg, $topoId;
    for (my $i=0; $i < 15; $i++) {
        push @bindArg, (defined($topoArr[$i]->{"val"})) ? $topoArr[$i]->{"val"}:"*";
    }
    push @bindArg, $dbData->{"counterNm"};
    push @bindArg, $dbData->{"time"};
    @bindArg2 = map {$_;} @bindArg;
    my $rv = $sth->execute(@bindArg);
    if ($rv < 0) {
        $self->logmsg("Could not execute query (1): $DBI::errstr \n");
        $self->{"dbh"}->rollback();
        return;
    }
    my $res = $sth->fetchrow_hashref();
    if (!defined($res) && !$sth->err) {
        $sth = $self->{"dbh"}->prepare("insert into meas_vals (TopId, Key1, Key2, Key3, Key4, Key5, Key6, Key7, Key8, Key9, Key10, Key11, Key12, Key13, Key14, Key15, counter, meas_time, val) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, str_to_date(?, '%Y-%m-%d %H:%i:%s'), ?)");
        push @bindArg2, $dbData->{"counterVal"}; 
        $rv = $sth->execute(@bindArg2);
        if ($rv < 0) {
            $self->logmsg("Could not execute DML (2): $DBI::errstr \n");
            $self->{"dbh"}->rollback();
            return;
        }
    } else {
        if ($res->{"val"} != $dbData->{"counterVal"}) {
            $sth = $self->{"dbh"}->prepare("update meas_vals set val=?, agg_hour=0, agg_day=0, agg_week=0, agg_month=0 where TopId=? and Key1=? and Key2=? and Key3=? and Key4=? and Key5=? and Key6=? and Key7=? and Key8=? and Key9=? and Key10=? and Key11=? and Key12=? and Key13=? and Key14=? and Key15=? and counter=? and meas_time=str_to_date(?, '%Y-%m-%d %H:%i:%s')");
            unshift @bindArg2, $dbData->{"counterVal"};
            $rv = $sth->execute(@bindArg2);
            if ($rv < 0) {
                $self->logmsg("Could not execute DML (3): $DBI::errstr \n");
                $self->{"dbh"}->rollback();
                return;
            } 
        } 
    }
    $self->{"dbh"}->commit();
    return $topoId;
}
    
sub registerCount {
    my $self = shift;
    my $dbData = shift;
    my $topoId = shift;
    my $sth = $self->{"dbh"}->prepare("select count(*) as cnt from meas_types where TopId=? and counter=?");
    my (@bindArg, @bindArg2, @bindArg3);
    push @bindArg, $topoId;
    push @bindArg, $dbData->{"counterNm"};
    @bindArg2 = map {$_;} @bindArg;
    @bindArg3 = map {$_;} @bindArg;
    my $rv = $sth->execute(@bindArg);
    if ($rv < 0) {
        $self->logmsg("Could not execute query (4): $DBI::errstr \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    my $res = $sth->fetchrow_hashref();
    if ($res->{"cnt"} == 0) {
        $sth = $self->{"dbh"}->prepare("insert into meas_types (TopId, counter, percent, avgA, sumA, minA, maxA) values (?, ?, false, false, false, false, false)");
        $rv = $sth->execute(@bindArg2);
        if ($rv < 0) {
            $self->logmsg("Could not execute DML (5): $DBI::errstr \n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
    } 
    my @attr = split(/\;/, $dbData->{"counterAttr"});
    foreach my $agg (@attr) {
        next if ($agg !~ /^avg$|^sum$|^min$|^max$|^percent$/);
        @bindArg2 = map {$_;} @bindArg3;
        if ($agg !~ /^percent$/) {
            $agg .= "A";
        }
        $sth = $self->{"dbh"}->prepare("update meas_types set $agg=true where TopId=? and counter=?");
        $rv = $sth->execute(@bindArg2);
        if ($rv < 0) {
            $self->logmsg("Could not execute DML (6): $DBI::errstr \n");
            $self->{"dbh"}->rollback();
            return(-1);
        } 
    }
    $sth = $self->{"dbh"}->prepare("select count(*) as cnt from count_desc where TopId=? and counter=?");
    @bindArg2 = map {$_;} @bindArg3;
    my $rv = $sth->execute(@bindArg2);
    if ($rv < 0) {
        $self->logmsg("Could not execute query (7): $DBI::errstr \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    my $res = $sth->fetchrow_hashref();
    if ($res->{"cnt"} == 0) {
        @bindArg2 = map {$_;} @bindArg3;
        $sth = $self->{"dbh"}->prepare("insert into count_desc (TopId, counter, countDesc) values (?, ?, NULL)");
        $rv = $sth->execute(@bindArg2);
        if ($rv < 0) {
            $self->logmsg("Could not execute DML (8): $DBI::errstr \n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
    } 
    @bindArg2 = map {$_;} @bindArg3;
    $sth = $self->{"dbh"}->prepare("update count_desc set countDesc=? where TopId=? and counter=?");
    unshift @bindArg2, $dbData->{"counterDesc"};
    $rv = $sth->execute(@bindArg2);
    if ($rv < 0) {
        $self->logmsg("Could not execute DML (9): $DBI::errstr \n");
        $self->{"dbh"}->rollback();
        return(-1);
    } 
    return(0);
}
    
sub registerTopo {
    my $self = shift;
    my $topoArr = shift;
    my $topIdMap = shift;
    my $topoId;
    my @topoArr = map {$_;} @{$topoArr};
    my $sth = $self->{"dbh"}->prepare("select TopId from topo_def where TKey1=? and TKey2=? and TKey3=? and TKey4=? and TKey5=? and TKey6=? and TKey7=? and TKey8=? and TKey9=? and TKey10=? and TKey11=? and TKey12=? and TKey13=? and TKey14=? and TKey15=?");
    my (@bindArg, @bindArg2);
    for (my $i=0; $i < 15; $i++) {
        push @bindArg, (defined($topoArr[$i]->{"key"})) ? $topoArr[$i]->{"key"}:"*";
    }
    @bindArg2 = map {$_;} @bindArg;
    my $rv = $sth->execute(@bindArg);
    if ($rv < 0) {
        $self->logmsg("Could not execute query (10): $DBI::errstr \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    my $res = $sth->fetchrow_hashref();
    if (defined($res->{"TopId"})) {
        $topoId = $res->{"TopId"};
    } else {
        $sth = $self->{"dbh"}->prepare("select max(TopId) as t from topo_def");
        $rv = $sth->execute();
        if ($rv < 0) {
            $self->logmsg("Could not execute query (11): $DBI::errstr \n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
        $res = $sth->fetchrow_hashref();
        if (defined($res->{"t"})) {
            $topoId = $res->{"t"} + 1;
        } else {
            $topoId = 1;
        }
        $sth = $self->{"dbh"}->prepare("insert into topo_def (TopId, TKey1, TKey2, TKey3, TKey4, TKey5, TKey6, TKey7, TKey8, TKey9, TKey10, TKey11, TKey12, TKey13, TKey14, TKey15) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        unshift @bindArg2, $topoId; 
        $rv = $sth->execute(@bindArg2);
        if ($rv < 0) {
            $self->logmsg("Could not execute DML (12): $DBI::errstr \n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
        $sth->finish();
    }
    if (defined($topIdMap)) {
        $sth = $self->{"dbh"}->prepare("select count(*) as c from topo_map where TopId=?");
        my @bindArg4 = ($topoId);
        $rv = $sth->execute(@bindArg4);
        if ($rv < 0) {
            $self->logmsg("Could not execute DML (12.4): $DBI::errstr \n");
            $self->{"dbh"}->rollback();
            return(-1);
        }
        $res = $sth->fetchrow_hashref();
        if ($res->{"c"} == 0) { 
            $sth = $self->{"dbh"}->prepare("insert into topo_map (TopId, countTopId, keyMap1, keyMap2, keyMap3, keyMap4, keyMap5, keyMap6, keyMap7, keyMap8, keyMap9, keyMap10, keyMap11, keyMap12, keyMap13, keyMap14, keyMap15) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            my @bindArg4 = ($topoId, $topIdMap->{"countTopId"}, $topIdMap->{"key1"},$topIdMap->{"key2"},$topIdMap->{"key3"},$topIdMap->{"key4"},$topIdMap->{"key5"},$topIdMap->{"key6"},$topIdMap->{"key7"},$topIdMap->{"key8"},$topIdMap->{"key9"},$topIdMap->{"key10"},$topIdMap->{"key11"},$topIdMap->{"key12"},$topIdMap->{"key13"},$topIdMap->{"key14"},$topIdMap->{"key15"});
            $rv = $sth->execute(@bindArg4);
            if ($rv < 0) {
                $self->logmsg("Could not execute DML (12.5): $DBI::errstr \n");
                $self->{"dbh"}->rollback();
                return(-1);
            }
        }
    }
    my @bindArg3;
    for (my $i=0; $i < 15; $i++) {
        push @bindArg3, $topoArr[$i]->{"desc"};
    }
    $sth = $self->{"dbh"}->prepare("delete from topo_desc where TopId=?");
    $rv = $sth->execute($topoId);
    if ($rv < 0) {
        $self->logmsg("Could not execute DML (13): $DBI::errstr \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    $sth = $self->{"dbh"}->prepare("insert into topo_desc (TopId, TKeyDesc1, TKeyDesc2, TKeyDesc3, TKeyDesc4, TKeyDesc5, TKeyDesc6, TKeyDesc7, TKeyDesc8, TKeyDesc9, TKeyDesc10, TKeyDesc11, TKeyDesc12, TKeyDesc13, TKeyDesc14, TKeyDesc15) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    unshift @bindArg3, $topoId; 
    $rv = $sth->execute(@bindArg3);
    if ($rv < 0) {
        $self->logmsg("Could not execute DML (14): $DBI::errstr \n");
        $self->{"dbh"}->rollback();
        return(-1);
    }
    return($topoId);
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
