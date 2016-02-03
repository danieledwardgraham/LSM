package statPull;

use Sys::Hostname;
use IO::Socket;
use IO::Handle;
use Carp;
use Data::Dumper;
use POSIX ":sys_wait_h";
use strict;

sub spawn;

sub new {
    my $class = shift;
    my $args = shift;
    my $self = { };
    $self->{"port"} = $args->{"port"} || $ENV{"LSM_SERVERPORT"} || die "LSM_SERVERPORT not set\n";
    $self->{"server"} = IO::Socket::INET->new(LocalHost => '127.13.72.1', LocalPort => $self->{"port"},
                                Type      => SOCK_STREAM,
                                Reuse     => 1,
                                Proto     => 'tcp',
                                Listen    => 20)
       or (statPull->logmsg("Error starting server on port $self->{'port'}: $@\n") &&
           die "Error starting server - check error log.");
    $self->{"server"}->autoflush(1);
    return bless($self, $class);
}

my $waitedpid = 0;

sub REAPER {
    while (($waitedpid = waitpid(-1,WNOHANG)) > 0) {
        logmsg({ }, "end ETL cmd $waitedpid" . ($? ? " with exit $?" : ''));
    }
    $SIG{CHLD} = \&REAPER;
} 

sub pull {
    my $self = shift;
    my $sobj = shift;
    $SIG{CHLD} = \&REAPER;
    my ($xml, $client, $client_ip, $client_address, $client_port, $client__packed_ip);
    my $EOL = "\015\012";
    for ( $waitedpid = 0; (($client, $client_address) = $self->{"server"}->accept()) || 1; $waitedpid = 0, close $client if defined($client))
    {
        next if not defined($client);
        $client->autoflush(1);
        ($client_port, $client__packed_ip) = sockaddr_in($client_address);
        $client_ip = inet_ntoa($client__packed_ip); 
        $self->logmsg("connection from [$client_ip] at port [$client_port]\n");
        $self->spawn(sub {
            $|=1;
            my $myclient = shift;
            local $SIG{TERM} = sub {
               $self->logmsg("received TERM signal, terminating socket...\n");
               close($myclient);
               exit;
            };
            $xml = join('', <STDIN>);
            $xml =~ s/$EOL//g;
            $sobj->procStats($xml);
            close($myclient);
            return 0;
            }, $client);
   }
   close($self->{"server"});
}

sub spawn {
    my $self = shift;
    my $coderef = shift;
    my $client = shift;
    unless (@_ == 0 && $coderef && ref($coderef) eq 'CODE') {
        confess "usage: spawn CODEREF";
    }
    my $pid;
    if (!defined($pid = fork)) {
        $self->logmsg("cannot fork: $! \n");
        return;
    } elsif ($pid) {
        return;
    }
    my $filedesc = $client->fileno;
    open(STDIN, "<&=$filedesc") || die "can't dup client to stdin [$!] [".$filedesc."]";
#    open(STDOUT, ">&=$filedesc") || die "can't dup stdout to client [$!] [$filedesc]";
#    open(STDERR, ">&STDOUT") || die "can't dup stdout to stderr [$!] [$filedesc]";
    exit &$coderef($client);
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
    return(1);
}

1;
