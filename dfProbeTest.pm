# Class : dfProbeTest
# This tests the dfProbe class with result XML going to sample.xml instead of the socket.
# v.1.0, Dan Graham, 10/8/2009

package dfProbeTest;

use dfProbe;
@ISA = ('dfProbe');

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
