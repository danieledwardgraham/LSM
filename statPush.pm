# Class : statPush
# This class implements a probe statistics push strategy to the central server
# v.1.0, 10/6/2009, Dan Graham
#

package statPush;

use IO::Socket::INET;

sub new {
    my $class = shift;
    my $args = shift;
    my $port = $args->{"port"} || $ENV{"LSM_SERVERPORT"};
    die "Error: Environment variable LSM_SERVERPORT not defined\n" if (!defined($port));
    my $server = $args->{"server"} || "localhost";
    my $self = { };
    $self->{"port"} = $port;
    $self->{"server"} = $server;
    return bless($self, $class);
}

sub push {
    my $self = shift;
    my $fifo = shift;
    my $sock = IO::Socket::INET->new(PeerAddr => $self->{"server"},
                                PeerPort => $self->{"port"},
                                Proto => 'tcp');
    $sock->autoflush(1);
    open(INFILE, $fifo);
    while (<INFILE>) {
        $sock->print($_."\n");
    }
    close(INFILE);
    $sock->close();
}

1;
