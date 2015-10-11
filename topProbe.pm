# Class : topProbe
# This class represents a statistics generator for a probe running the "top" command.
# v.1.0, Dan Graham, 10/8/2009

package topProbe;

use contRunningProbe;
@ISA = ('contRunningProbe');

use Data::Dumper;
use strict;

sub new {
    my $class = shift;
    my $args = shift;
    if (!defined($args)) {
        $args = { 'cmd' => 'top' };
    } else {
        $args->{"cmd"} = 'top';
    }
    my $self = $class->SUPER::new($args);
    return bless($self, $class);
}

sub getSubStats {
    my $self = shift;
    my (@arr, $pid, $owner, $pcpu, $pmem, $cmd, $memFree, $swapFree, $memTot, $swapTot);
    my ($st, $dataln);
    for ($st = 1; $st < 35; $st++) {
        last if ($self->{"vt"}->row_plaintext($st) =~ /^\s*PID.*$/);
    }
    for (my $i = $st+1; $i < $st+16; $i++) {     
        $dataln = $self->{"vt"}->row_plaintext($i);
        $dataln =~ s/^\s*(.*?)$/$1/g;
        @arr = split(/\s+/, $dataln);
        if (@arr == 12) {
            $pid = $arr[0];
            $owner = $arr[1];
            $pcpu = $arr[8];
            $pmem = $arr[9];
            $cmd = $arr[11];
            if (!defined($self->{"subStats"}->{"$pid"})) {
               $self->{"subStats"}->{"$pid"} = { };
            } 
            $self->{"subStats"}->{"$pid"}->{"owner"} = $owner;
            $self->{"subStats"}->{"$pid"}->{"cmd"} = $cmd;
            if ($self->{"subStats"}->{"$pid"}->{"maxCpu"} <= $pcpu) {
               $self->{"subStats"}->{"$pid"}->{"maxCpu"} = $pcpu + 0;
            }
            if ($self->{"subStats"}->{"$pid"}->{"maxMem"} <= $pmem) {
               $self->{"subStats"}->{"$pid"}->{"maxMem"} = $pmem + 0;
            }
            $self->{"subStats"}->{"$pid"}->{"totCpu"} += $pcpu;
            $self->{"subStats"}->{"$pid"}->{"totMem"} += $pmem;
        }
    }
    $self->{"subStats"}->{"cnt"} += 1;
    for ($st = 1; $st < 35; $st++) {
        last if ($self->{"vt"}->row_plaintext($st) =~ /^\s*Mem\:.*$/);
    }
    @arr = split(/ +/, $self->{"vt"}->row_plaintext($st));
    if (@arr == 9) {
        $memFree = $arr[5];
        $memFree =~ s/^(.*)k$/$1/g;
        $memTot = $arr[1];
        $memTot =~ s/^(.*)k$/$1/g;
        $memFree = ($memFree / $memTot) * 100;
        if ((!defined($self->{"subStats"}->{"minMemFree"})) || ($self->{"subStats"}->{"minMemFree"} > $memFree)) {
            $self->{"subStats"}->{"minMemFree"} = sprintf("%8.4f", $memFree);
        }
        $self->{"subStats"}->{"totMemFree"} += $memFree;
        $self->{"subStats"}->{"totMemFreeCnt"} += 1;
    }
    for ($st = 1; $st < 35; $st++) {
        last if ($self->{"vt"}->row_plaintext($st) =~ /^\s*Swap\:.*$/);
    }
    @arr = split(/ +/, $self->{"vt"}->row_plaintext($st));
    if (@arr == 9) {
        $swapFree = $arr[5];
        $swapFree =~ s/^(.*)k$/$1/g;
        $swapTot = $arr[1];
        $swapTot =~ s/^(.*)k$/$1/g;
        $swapFree = ($swapFree / $swapTot) * 100;
        if ((!defined($self->{"subStats"}->{"minSwapFree"})) || ($self->{"subStats"}->{"minSwapFree"} > $swapFree)) {
            $self->{"subStats"}->{"minSwapFree"} = sprintf("%8.4f", $swapFree);
        }
        $self->{"subStats"}->{"totSwapFree"} += $swapFree;
        $self->{"subStats"}->{"totSwapFreeCnt"} += 1;
    } 
    return;
}

sub getStats {
    my $self = shift;
    my @hashSave;
    my $hashCnt = 0;
    my $retArr = [ ];
    my @memArr;
    my @cpuArr;
    my ($totMemFree, $totMemFreeCnt, $totSwapFree, $totSwapFreeCnt, $minMemFree, $minSwapFree, $cnt);
    $cnt = $self->{"subStats"}->{"cnt"};
    foreach my $i (keys %{$self->{"subStats"}}) {
       if ($i eq  "totMemFree") {
           $totMemFree = $self->{"subStats"}->{"$i"};
           next;
       } 
       if ($i eq  "totMemFreeCnt") {
           $totMemFreeCnt = $self->{"subStats"}->{"$i"};
           next;
       } 
       if ($i eq  "totSwapFree") {
           $totSwapFree = $self->{"subStats"}->{"$i"};
           next;
       } 
       if ($i eq  "totSwapFreeCnt") {
           $totSwapFreeCnt = $self->{"subStats"}->{"$i"};
           next;
       } 
       if ($i eq  "minMemFree") {
           $minMemFree = $self->{"subStats"}->{"$i"};
           next;
       } 
       if ($i eq  "minSwapFree") {
           $minSwapFree = $self->{"subStats"}->{"$i"};
           next;
       } 
       if ($i eq "cnt") {
           next;
       }
       $hashSave[$hashCnt] = { };
       $hashSave[$hashCnt]->{"pid"} = $i;
       $hashSave[$hashCnt]->{"command"} = $self->{"subStats"}->{"$i"}->{"cmd"};
       $hashSave[$hashCnt]->{"owner"} = $self->{"subStats"}->{"$i"}->{"owner"};
       $hashSave[$hashCnt]->{"avgPercent"} = sprintf("%8.4f",$self->{"subStats"}->{"$i"}->{"totMem"} / $cnt);
       $hashSave[$hashCnt]->{"maxPercent"} = $self->{"subStats"}->{"$i"}->{"maxMem"};
       push @memArr, $hashSave[$hashCnt++];
       $hashSave[$hashCnt] = { };
       $hashSave[$hashCnt]->{"pid"} = $i;
       $hashSave[$hashCnt]->{"command"} = $self->{"subStats"}->{"$i"}->{"cmd"};
       $hashSave[$hashCnt]->{"owner"} = $self->{"subStats"}->{"$i"}->{"owner"};
       $hashSave[$hashCnt]->{"avgPercent"} = sprintf("%8.4f", $self->{"subStats"}->{"$i"}->{"totCpu"} / $cnt);
       $hashSave[$hashCnt]->{"maxPercent"} = $self->{"subStats"}->{"$i"}->{"maxCpu"};
       push @cpuArr, $hashSave[$hashCnt++];
    }
    $hashSave[$hashCnt] = { };
    $hashSave[$hashCnt]->{"mem"} = \@memArr; 
    push @{$retArr}, $hashSave[$hashCnt++];
    $hashSave[$hashCnt] = { };
    $hashSave[$hashCnt]->{"cpu"} = \@cpuArr; 
    push @{$retArr}, $hashSave[$hashCnt++];
    $hashSave[$hashCnt] = { };
    $hashSave[$hashCnt]->{"minSwapFree"} = $minSwapFree; 
    push @{$retArr}, $hashSave[$hashCnt++];
    $hashSave[$hashCnt] = { };
    $hashSave[$hashCnt]->{"minMemFree"} = $minMemFree; 
    push @{$retArr}, $hashSave[$hashCnt++];
    $hashSave[$hashCnt] = { };
    $hashSave[$hashCnt]->{"avgMemFree"} = sprintf("%8.4f", $totMemFree / $totMemFreeCnt); 
    push @{$retArr}, $hashSave[$hashCnt++];
    $hashSave[$hashCnt] = { };
    $hashSave[$hashCnt]->{"avgSwapFree"} = sprintf("%8.4f", $totSwapFree / $totSwapFreeCnt); 
    push @{$retArr}, $hashSave[$hashCnt++];
    $self->{"statistics"} = $retArr;
    return;
}

1;

