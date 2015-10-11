# Class : dfProbe 
# Desc  : This class implements the "df -k" probe that is a subclass of "sampleProbe".
# v.1.0, Dan Graham, 11/15/2009

package dfProbe;

use sampleProbe;
@ISA = ("sampleProbe");

use Config;
use strict;

sub new {
    my $class = shift;
    my $args = shift;
    $args->{"cmd"} = "df -k";
    my $self = $class->SUPER::new($args);
    return bless($self, $class);
}

sub getStats {
    my $self = shift;
    $self->SUPER::getStats();
    shift @{$self->{"cmdResults"}};
    my $filesystem = "";
    my $mount = "";
    my $capacity = "";
    my $avail = "";
    my @arr;
    my @hashArr;
    my $hashCnt = 0;
    my $item;
    my @diskArr;
    foreach my $ln (@{$self->{"cmdResults"}}) {
        @arr = split(/\s+/, $ln);
        $filesystem = $arr[0] if ($arr[0] ne "");
        chomp($filesystem);
        $mount = $arr[@arr - 1];
        $capacity = $arr[@arr - 2];
        $avail = $arr[@arr - 3];
        if ($capacity =~ /(.*)\%/) {
            $capacity = $1;
            $hashArr[$hashCnt] = { };
            $item = $hashArr[$hashCnt++];
            $item->{"filesystem"} = $filesystem;
            $item->{"mount"} = $mount;
            $item->{"avail"} = $avail;
            $item->{"capacity"} = $capacity;
            push @diskArr, $item;
        }
    }
    my $ret = { };
    $ret->{"disk"} = \@diskArr;
    push @{$self->{"statistics"}}, $ret;
}
  
1;
