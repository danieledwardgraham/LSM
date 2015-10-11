# Class : dfProbeTest
# This tests the trafshowProbe class with result XML going to sample.xml instead of the socket.
# v.1.0, Dan Graham, 11/20/2009

package trafshowProbeTest;

use trafshowProbe;
@ISA = ('trafshowProbe');

sub new {
    my $class = shift;
    my $args = shift;
    my $self = $class->SUPER::new($args);
    return bless($self, $class);
}

sub transferStats {
    my $self = shift;
    open (INFILE, $self->{"fifo"});
    open (OUTFILE, ">>sample.xml");
    while (<INFILE>) {
        print OUTFILE $_."\n";
    }
    close(OUTFILE);
    close(INFILE);
    return;
}
