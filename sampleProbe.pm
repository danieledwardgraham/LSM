# Class : sampleProbe 
# Desc  : This class implements the "sampling probe" that is a subclass of "probe".
# v.1.0, Dan Graham, 11/14/2009

package sampleProbe;

use probe;
@ISA = ("probe");

use Config;
use strict;

sub new {
    my $class = shift;
    my $args = shift;
    my $self = $class->SUPER::new($args);
    $self->{"cmd"} = $args->{"cmd"};
    $self->{"cmdResults"} = [ ];
    return bless($self, $class);
}

sub getStats {
    my $self = shift;
    $self->{"cmdResults"} = [ ];
    open(CMD, $self->{"cmd"}."|");
    map {push @{$self->{"cmdResults"}}, $_;} <CMD>;
    close(CMD);
} 

1;
