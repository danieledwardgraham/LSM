# Class : trafshowProbe
# This class represents a statistics generator for a probe running the "trafshow" command.
# v.1.0, Dan Graham, 11/20/2009

package trafshowProbe;

use contRunningProbe;
@ISA = ('contRunningProbe');

use Data::Dumper;
use strict;

sub new {
    my $class = shift;
    my $args = shift;
    if (!defined($args)) {
        $args = { 'cmd' => 'trafshow -i eth0' };
    } else {
        $args->{"cmd"} = 'trafshow -i eth0';
    }
    my $self = $class->SUPER::new($args);
    $self->{"portHash"} = { };
    open (INFILE, $class.".ports") or die "Can not find $class".".ports file";
    foreach my $x (<INFILE>) {
        chomp($x);
        $self->{"portHash"}->{"$x"} = 1;
    }
    close(INFILE);
    return bless($self, $class);
}

sub getSubStats {
    my $self = shift;
    my (@arr, @hashSave, %seen);
    my $hashCnt = 0;
    my ($dataln, $protocol, $destServ, $srcServ, $destIp, $srcIp, $size, $cps, $key, $kbps);
    for (my $i = 1; $i<35; $i++) {
        $dataln = $self->{"vt"}->row_plaintext($i);
        @arr = split(/\s+/, $dataln);
        if ($arr[2] eq "udp" || $arr[2] eq "tcp") {
            ($destIp, $destServ) = split(/\,/, $arr[1]);
            ($srcIp, $srcServ) = split(/\,/, $arr[0]);
            $protocol = $arr[2];
            $size = $arr[3];
            if ($size =~ /^(.*)[kK]$/) {
                $size = $1;
                $size *= 1000;
            }
            if ($size =~ /^(.*)[mM]$/) {
                $size = $1;
                $size *= 1000000;
            }
            $size = $size/1000;
            $cps = $arr[4];
            if ($cps =~ /^(.*)[kK]$/) {
                $cps = $1;
                $cps *= 1000;
            }
            if ($cps =~ /^(.*)[mM]$/) {
                $cps = $1;
                $cps *= 1000000;
            }
            $kbps = ($cps * 8)/1000;
            $key = "$protocol|$destServ|$srcServ|$destIp|$srcIp"; 
            if (!defined($self->{"subStats"}->{"$key"})) {
                $hashSave[$hashCnt] = { };
                $self->{"subStats"}->{"$key"} = $hashSave[$hashCnt++];
            }
            $self->{"subStats"}->{"$key"}->{"size"} = $size;
            $self->{"subStats"}->{"$key"}->{"seenCnt"}++ if ($kbps > 0);
            $self->{"subStats"}->{"$key"}->{"sumKbps"} += $kbps;
            if ($kbps > $self->{"subStats"}->{"$key"}->{"maxKbps"}) {
                $self->{"subStats"}->{"$key"}->{"maxKbps"} = $kbps;
            }
            $seen{"$key"} = 1;
        }
    }
    foreach my $k (keys %seen) {
        if (!($self->{"subStats"}->{"$k"}->{"seen"} > 0)) {
            $self->{"subStats"}->{"$k"}->{"sumSize"} += $self->{"subStats"}->{"$k"}->{"size"};
            $self->{"subStats"}->{"$k"}->{"seen"} = 1;
        }
    }
    foreach my $k (keys %{$self->{"subStats"}}) {
        if (!defined($seen{"$k"}) && $k ne "totalCnt") {
            $self->{"subStats"}->{"$k"}->{"seen"} = 0;
        }
    } 
    $self->{"subStats"}->{"totalCnt"}++;
    return;
}

sub getStats {
    my $self = shift;
    my @hashSave;
    my $hashCnt = 0;
    my $retArr = [ ];
    my $retHash = { };
    my @netArr;
    my ($protocol, $destServ, $srcServ, $destIp, $srcIp, $sumSize, $netstat);
    foreach my $k (keys %{$self->{"subStats"}}) {
        next if ($k eq "totalCnt");
        $hashSave[$hashCnt] = { };
        $netstat = $hashSave[$hashCnt++];
        ($protocol, $destServ, $srcServ, $destIp, $srcIp) = split(/\|/, $k);
        $sumSize = $self->{"subStats"}->{"$k"}->{"sumSize"};
        if ($self->{"subStats"}->{"$k"}->{"seen"} > 0) {
            $sumSize += $self->{"subStats"}->{"$k"}->{"size"};
        }
        $netstat->{"sumSize"} = sprintf("%8.4f", $sumSize);
        $netstat->{"avgKbps"} = sprintf("%8.4f", $self->{"subStats"}->{"$k"}->{"sumKbps"} / (($self->{"subStats"}->{"$k"}->{"seenCnt"} > 0) ? $self->{"subStats"}->{"$k"}->{"seenCnt"} : 1));
        $netstat->{"timAvgKbps"} = sprintf("%8.4f", $self->{"subStats"}->{"$k"}->{"sumKbps"} / $self->{"subStats"}->{"totalCnt"});
        $netstat->{"maxKbps"} = sprintf("%8.4f", $self->{"subStats"}->{"$k"}->{"maxKbps"} + 0); 
        $netstat->{"protocol"} = $protocol;
        if ($destServ =~ /^[0-9]+$/) {
            $destServ = "client port" unless (defined($self->{"portHash"}->{"$destServ"}));
        }
        $netstat->{"destServ"} = $destServ;
        if ($srcServ =~ /^[0-9]+$/) {
            $srcServ = "client port" unless (defined($self->{"portHash"}->{"$srcServ"}));
        }
        $netstat->{"srcServ"} = $srcServ;
        $netstat->{"destHost"} = $destIp;
        $netstat->{"srcHost"} = $srcIp;
        push @netArr, $netstat;
    }
    $retHash->{"network"} = \@netArr; 
    push @{$retArr}, $retHash;
    $self->{"statistics"} = $retArr;
    $self->sendCmd("\cR");
    return;
}

1;

