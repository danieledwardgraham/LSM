# Class : lastProbe 
# Desc  : This class implements the "last" probe that is a subclass of "sampleProbe".
# v.1.0, Dan Graham, 11/18/2009

package lastProbe;

use sampleProbe;
@ISA = ("sampleProbe");

use Time::Local;
use Config;
use strict;

sub new {
    my $class = shift;
    my $args = shift;
    $args->{"cmd"} = "last";
    my $self = $class->SUPER::new($args);
    return bless($self, $class);
}

sub getStats {
    my $self = shift;
    $self->SUPER::getStats();
    my $user = "";
    my $pty = "";
    my $ip = "";
    my $meas_time = "";
    my $duration = "";
    my $os = "";
    my @arr;
    my @hashArr;
    my $hashCnt = 0;
    my $item;
    my (@rebootArr, @loginArr);
    foreach my $ln (@{$self->{"cmdResults"}}) {
        next if ($ln =~ /^$/ || $ln =~ /^wtmp/);
        @arr = split(/\s+/, $ln);
        $hashArr[$hashCnt] = { };
        $item = $hashArr[$hashCnt++];
        if ($ln =~ /^reboot/) {
            $os = $arr[3];
            $meas_time = $self->computeDate("$arr[5] $arr[6] $arr[7]");
            $duration = $self->computeDuration($arr[@arr - 1]);
            $item->{"os"} = $os;
            $item->{"meas_time"} = $meas_time;
            $item->{"duration"} = $duration;
            push @rebootArr, $item; 
        } else {
            $user = $arr[0];
            $pty = $arr[1];
            if ($pty !~ /pts/) {
                $ip = "local";
                $meas_time = $self->computeDate("$arr[3] $arr[4] $arr[5]");
            } else {
                $ip = $arr[2];
                $meas_time = $self->computeDate("$arr[4] $arr[5] $arr[6]");
            }
            if ($ln =~ /still logged in/) {
                $duration = $self->computeNowDuration($meas_time);
            } else {
                $duration = $self->computeDuration($arr[@arr - 1]);
            }
            $item->{"user"} = $user;
            $item->{"pty"} = $pty;
            $item->{"ip"} = $ip;
            $item->{"meas_time"} = $meas_time;
            $item->{"duration"} = $duration;
            push @loginArr, $item;
        }    
    }
    if (@rebootArr) {
        my $ret = { };
        $ret->{"reboot"} = \@rebootArr;
        push @{$self->{"statistics"}}, $ret;
    }
    if (@loginArr) {
        my $ret2 = { };
        $ret2->{"login"} = \@loginArr;
        push @{$self->{"statistics"}}, $ret2;
    }
}

sub computeDate {
    my $self = shift;
    my $arg = shift;
    my %months = ( 'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5,
                   'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10,
                   'Nov' => 11, 'Dec' => 12 );
    my ($mon, $mday, $hourMin) = map {$months{$_} || $_;} split(/\s+/, $arg);
    my ($hour, $min) = split(/\:/, $hourMin);
    my ($secN,$minN,$hourN,$mdayN,$monN,$yearN,$wdayN,$ydayN,$isdstN) = localtime(time); 
    my $epochTime = timelocal(0, $min, $hour, $mday, $mon - 1, ($monN >= ($mon - 1)) ? $yearN:($yearN - 1));
    my ($secRet,$minRet,$hourRet,$mdayRet,$monRet,$yearRet,$wdayRet,$ydayRet,$isdstRet) = gmtime($epochTime);
    $yearRet += 1900;
    $monRet++;
    my $ret = sprintf("%04d%02d%02d%02d%02d%02d", $yearRet, $monRet, $mdayRet, $hourRet, $minRet, $secRet);
    return $ret;
}

sub computeNowDuration {
    my $self = shift;
    my $arg = shift;
    my ($year, $mon, $mday, $hour, $min, $sec) = (substr($arg, 0, 4), substr($arg, 4, 2), substr($arg, 6, 2), substr($arg, 8, 2), substr($arg, 10, 2), substr($arg, 12, 2));
    my $epochTime = timegm($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
    my $ret = (time - $epochTime)/3600;
    my $retStr = sprintf("%8.4f", $ret);
    return $retStr;
}

sub computeDuration {
    my $self = shift;
    my $arg = shift;
    my $dur = 0;
    $arg =~ s/^\((.*)\)$/$1/g;
    my $days = $arg;
    $days =~ s/^(.*)\+.*$/$1/g;
    if ($days ne $arg) {
        $dur += $days * 24 * 60;
        $arg =~ s/^.*\+(.*)$/$1/g;
    }
    my ($hour, $min) = split(/\:/, $arg);
    $dur += $hour * 60 + $min;
    my $ret = $dur/60;
    my $retStr = sprintf("%8.4f", $ret);
    return $retStr;
}
    
1;
