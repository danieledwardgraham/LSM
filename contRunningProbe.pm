# Class : contRunningProbe
# Desc  : This class implements the "continuously running probe" that is a subclass of "probe".
# v.1.0, Dan Graham, 10/8/2009

package contRunningProbe;

use probe;
@ISA = ("probe");

use Term::VT102;
use IO::Handle;
use POSIX ':sys_wait_h';
use IO::Pty;
use Config;
use strict;

my $instanceKey;
my %PTY;

sub new {
    my $class = shift;
    my $args = shift;
    my $self = $class->SUPER::new($args);
    $instanceKey = $self->getInstanceKey();
    $self->{"cmd"} = $args->{"cmd"};
    $self->{"vt"} = Term::VT102->new (
        'cols' => 124,
        'rows' => 35,
        );
    $self->{"vt"}->option_set ('LFTOCRLF', 1);
    $self->{"vt"}->option_set ('LINEWRAP', 1);
    $PTY{$instanceKey} = new IO::Pty;
    $self->{"tty_name"} = $PTY{$instanceKey}->ttyname ();
    if (not defined $self->{"tty_name"}) {
	$self->logmsg("Error: Could not assign a pty");
        return(undef);
    }
    $PTY{$instanceKey}->autoflush ();
    $self->{"subStats"} = { };
    return bless($self, $class);
}
    
sub startCmd {
    my $self = shift;
    $| = 1;
    my $pid = fork;
    if (not defined $pid) {
	$self->logmsg("Error: Cannot fork: $!");
        return;
    } elsif ($pid == 0) {
	if (not POSIX::setsid ()) {
		$self->logmsg("Warning: Couldn't perform setsid: $!");
	}

        local $SIG{'TERM'} = sub {
            $self->logmsg("stopping cmd $self->{'cmd'}...");
            $self->{"subpid"} = undef;
            exit(0);
        };
	my $tty = $PTY{$instanceKey}->slave ();
	$self->{"tty_name"} = $tty->ttyname();
	close ($PTY{$instanceKey});
	close (STDOUT);
#	if (!open ($self->{"inCmd"}, "<&" . $tty->fileno ())) {
	if (!open (INCMD, "<&" . $tty->fileno ())) {
	    $self->logmsg("Error: couldn't reopen " . $self->{"tty_name"} . " for reading: $!");
            return;
        }
	if (!open (STDOUT, ">&" . $tty->fileno())) {
	    $self->logmsg("Error: couldn't reopen " . $self->{"tty_name"} . " for writing: $!");
            return;
        }
	close (STDERR);
	if (!open (STDERR, ">&" . $tty->fileno())) {
	    $self->logmsg("Error: couldn't redirect STDERR: $!");
            return;
        }
	system 'stty sane';

	system 'stty rows ' . $self->{"vt"}->rows;
	system 'stty cols ' . $self->{"vt"}->cols;

	exec $self->{"cmd"};
	$self->logmsg("Error: cannot exec $self->{'cmd'}: $!");
    }
    $self->logmsg("started $self->{'cmd'}");
    $self->{"subpid"} = $pid;
    $self->{"vt"}->callback_set ('OUTPUT', \&vt_output, $PTY{$instanceKey});
    $self->{"changedrows"} = {};
    $self->{"vt"}->callback_set ('ROWCHANGE', \&vt_rowchange, $self->{"changedrows"});
    $self->{"vt"}->callback_set ('CLEAR', \&vt_changeall, $self->{"changedrows"});
    $self->{"vt"}->callback_set ('SCROLL_UP', \&vt_changeall, $self->{"changedrows"});
    $self->{"vt"}->callback_set ('SCROLL_DOWN', \&vt_changeall, $self->{"changedrows"});
    $pid = fork;
    if (not defined $pid) {
	$self->logmsg("Error: cannot fork(2): $!");
        return;
    } elsif ($pid == 0) {
        $self->monitorCmd();
    }
   $self->{"subpid2"} = $pid; 
    return;
}

sub stopCmd {
    my $self = shift;
    if (!defined($self->{"subpid"})) {
        $self->logmsg("error: cmd not started - start cmd first");
        return;
    }
    my $i = 0;
    my (%signo, @signame);
    foreach my $name (split(' ', $Config{sig_name})) {
        $signo{$name} = $i;
        $signame[$i] = $name;
        $i++;
    }
    if (kill($signo{TERM}, $self->{"subpid2"}) < 1) {
        $self->logmsg("error: could not stop monitorCmd $self->{'cmd'}");
        return;
    }
    if (kill($signo{TERM}, $self->{"subpid"}) < 1) {
        $self->logmsg("error: could not stop cmd $self->{'cmd'}");
        return;
    }
    system 'stty sane';
    return;
}

sub monitorCmd {
    my $self = shift;
    my ($cmdbuf, $stdinbuf, $iot, $eof, $prevxy, $died);

    $iot = new IO::Handle;
#    $iot->fdopen (fileno($self->{"inCmd"}), 'r');
    $iot->fdopen (fileno(INCMD), 'r');
    $eof = 0;
    $prevxy = '';
    $died = 0;
    my $oldTime = time();
    while (not $eof) {
	my ($rin, $win, $ein, $rout, $wout, $eout, $nr, $didout);

        if ((time() - $oldTime) > $self->{"intervalSecs"}) {
            $oldTime = time();
            $self->getStats();
            $self->pushStats();
            $self->transferStats();
            $self->releaseStats();
        }
	($rin, $win, $ein) = ('', '', '');
	vec ($rin, $PTY{$instanceKey}->fileno, 1) = 1;
	vec ($rin, $iot->fileno, 1) = 1;

	select ($rout=$rin, $wout=$win, $eout=$ein, 1);

	$cmdbuf = '';
	$nr = 0;
	if (vec ($rout, $PTY{$instanceKey}->fileno, 1)) {
		$nr = $PTY{$instanceKey}->sysread ($cmdbuf, 1024);
		$eof = 1 if ((defined $nr) && ($nr == 0));
		if ((defined $nr) && ($nr > 0)) {
			$self->{"vt"}->process ($cmdbuf);
			syswrite STDERR, $cmdbuf if (! -t STDERR);
		}
	}

	$eof = 1 if ($died && $cmdbuf eq '');

	$stdinbuf = '';
	if (vec ($rout, $iot->fileno, 1)) {
		$nr = $iot->sysread ($stdinbuf, 16);
		$eof = 1 if ((defined $nr) && ($nr == 0));
		$PTY{$instanceKey}->syswrite ($stdinbuf, $nr) if ((defined $nr) && ($nr > 0));
	}

        $self->getSubStats();
	$died = 1 if (waitpid ($self->{"subpid"}, &WNOHANG) > 0);
    }
    return;
}

sub vt_output {
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;
    if ($type eq 'OUTPUT') {
	$PTY{$instanceKey}->syswrite ($arg1, length $arg1);
    }
    return;
}

sub vt_rowchange {
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;
    $private->{$arg1} = time if (not exists $private->{$arg1});
}

sub vt_changeall {
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;
    for (my $row = 1; $row <= $vtobject->rows; $row++) {
	$private->{$row} = 0;
    }
}

sub getSubStats {
# Derived class overrides this 
}

sub getStats {
# Derived class overrides this
}

sub start {
    my $self = shift;
    $self->startCmd();
    return;
}

sub stop {
    my $self = shift;
    $self->stopCmd();
    $self->SUPER::stop();
    system('stty sane');
    return;
}

sub sendCmd {
    my $self = shift;
    my $text = shift;
    $| = 1;
#    my $fh = $self->{"inCmd"};
#    print $fh $text;
    print INCMD $text;
    return;
} 

sub releaseStats {
    my $self = shift;
    $self->{"subStats"} = { };
    $self->SUPER::releaseStats();
    return;
}

1;
