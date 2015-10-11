# Class : Probe
# This module implements the base abstract class, probe.
# v.1.0, Dan Graham, 10/6/2009
#
package probe;

use strict;
use Carp;
use Config;
use POSIX qw(mkfifo);
use XML::Writer;
use IO::File;
use statPush;
use Data::Dumper;

my $probecnt = 0;

sub new {
    my $class = shift;
    my $args = shift;
    my $secs = $args->{"secs"};
    my $self = { };
    $self->{"intervalSecs"} = (defined($secs)) ? $secs:300;
    $self->{"statistics"} = ( );
    $self->{"pid"} = undef;
    $self->{"baseTopo"} = (defined($args->{"baseTopo"})) ? $args->{"baseTopo"}:[ ];
    $probecnt++;
    $self->{"fifo"} = "/tmp/probeFifo$$.$probecnt";
#    mkfifo($self->{"fifo"}, 0700) or die "mkfifo $self->{'fifo'} failed: $!";
    open(INFILE, $class.".conf");
    my $confText = join '', <INFILE>;
    close(INFILE);
    $self->{"conf"} = eval($confText);
    $self->{"transfer"} = statPush->new($args);
    return bless($self, $class);
}

sub start {
    my $self = shift;
    my $pid;
    if (defined($self->{"pid"})) {
        $self->logmsg("error: probe already started - stop probe first");
        return;
    }
    if (!defined($pid = fork)) {
        $self->logmsg("Error: cannot fork: $!");
        return;
    } elsif ($pid) {
        $self->logmsg("starting probe with pid $pid");
        $self->{"pid"} = $pid; 
        return;
    }
    local $SIG{'TERM'} = sub {
        $self->logmsg("stopping probe...");
        $self->{"pid"} = undef;
        exit(0);
    };
    while (1) {
        $self->getStats();
        $self->pushStats();
        $self->transferStats();
        $self->releaseStats();
        sleep($self->{"intervalSecs"});
    }
}

sub stop {
    my $self = shift;
    if (!defined($self->{"pid"})) {
        return;
    }
    my $i = 0;
    my (%signo, @signame);
    foreach my $name (split(' ', $Config{sig_name})) {
        $signo{$name} = $i;
        $signame[$i] = $name;
        $i++;
    }
    if (kill($signo{TERM}, $self->{"pid"}) < 1) {
        $self->logmsg("error: could not stop probe");
        return;
    }
    return;
}

sub getStats {
# Derived class overrides this
    return;
}

sub pushStats {
    my $self = shift;
#    $self->logmsg("Starting pushStats");
    my ($outputh);
    my $tmpfile = $self->{"fifo"};
    eval {
      $outputh = new IO::File(">".$tmpfile) or $self->logmsg("Error: $!");
    };
    if ($@) {
       $self->logmsg("Error: $@");
       exit;
    }
    my ($writer);
    eval {
       $writer = new XML::Writer(OUTPUT => $outputh, NEWLINES => 1) or $self->logmsg("Error: $!");
    };
    if ($@) {
        $self->logmsg("Error: $@");
        exit;
    }
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    $year += 1900;
    $mon++;
    my $statTime = sprintf("%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
    my $curtag = "LINUX";
    my $attrObj = $self->{"conf"};
#    my $stat = $self->{"statistics"};
#    my $stat = [ ];
#    foreach (@{$self->{"baseTopo"}}) {
#        push @{$stat}, $_;
#    }
#    push @{$stat}, $self->{"statistics"};
    my $stat = { };
    foreach my $k (@{$self->{"baseTopo"}}) {
        foreach (keys %{$k}) { 
            $stat->{"$_"} = $k->{"$_"};
        }
    }
    $stat->{"stats"} = $self->{"statistics"};
#    open(OUTFILE, ">datadump.txt");
#    print OUTFILE Dumper($stat);
#    close(OUTFILE);
    $self->_writeObj($writer, $stat, $curtag, $attrObj, $statTime);
    $writer->end();
    $outputh->close();
    return;
}

sub transferStats {
   my $self = shift;
   $self->{"transfer"}->push($self->{"fifo"});
   return;
} 
     
sub _writeObj {
   my $self = $_[0];
   my $writer = $_[1];
   my $obj = $_[2];
   my $curtag = $_[3];
   my $attrObj = $_[4];
   my $statTime = $_[5];
   my %attr;
   return if ($curtag =~ /^\s*$/);
#   if (defined($statTime)) {
   if ($curtag eq "stats") {
       $writer->startTag("$curtag", 'time' => "$statTime", "$curtag" => "system stats");
   } else {
        if (defined($attrObj->{"$curtag"."_attr"})) {
           %attr = split(/[\,\=]/, $attrObj->{"$curtag"."_attr"}); 
        }
       if (!defined($attr{"$curtag"})) {
           $attr{"$curtag"} = $curtag;
       }
       if (defined($attr{"key"})) {
           if (defined($attr{"counter"})) {
               $writer->startTag("$curtag", 'key' => $attr{key}, "$curtag" => "$attr{$curtag}", 'counter' => $attr{counter});
           } else {
               $writer->startTag("$curtag", 'key' => $attr{key}, "$curtag" => "$attr{$curtag}");
           }
       } else {
           if (defined($attr{"counter"})) {
               $writer->startTag("$curtag", 'counter' => $attr{counter}, "$curtag" => "$attr{$curtag}");
           } else {
               if ((ref($obj) eq "HASH") && (defined($obj->{"meas_time"}))) {
                   $writer->startTag("$curtag", 'time' => $obj->{"meas_time"}, "$curtag" => "$attr{$curtag}");
               } else {
                   $writer->startTag("$curtag", "$curtag" => "$attr{$curtag}");
               }
           }
       }
   } 
   my ($subobj);
   if (ref($obj) eq "ARRAY") {
#       foreach $subobj (@{$obj}) {
#           $self->_writeObj($writer, $subobj,$curtag."Item",$attrObj->{"$curtag"}, $statTime);
#       }
       while (@{$obj}) {
           $self->_writeObj($writer, shift @{$obj},$curtag."Item",$attrObj->{"$curtag"}, $statTime);
       }
   } else {
       if (ref($obj) eq "HASH") {
          foreach $subobj (keys %{$obj}) {
              next if ($subobj eq "meas_time");
              $self->_writeObj($writer, $obj->{"$subobj"}, $subobj, $attrObj, $statTime);
          }
        } else {
            $obj =~ s/\n/BRBRBR/g;
            $writer->characters($obj);
          } 
       }
    $writer->endTag("$curtag");
}

sub setTimeInterval {
    my $self = shift;
    my $secs = shift;
    $self->{"intervalSecs"} = (defined($secs)) ? $secs:300;
    return;
}

sub releaseStats {
    my $self = shift;
    $self->{"statistics"} = ( );
    unlink $self->{"fifo"};
    return;
}

sub logmsg {
    my $self = $_[0];
    my $msg = $_[1];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon++;
    my $logTime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
    open(OUTFILE, ">>/tmp/LSMprobe.log");
    print OUTFILE $logTime." ==> ".$msg."\n";
    close(OUTFILE);
    return;
}

sub getInstanceKey {
    my $self = shift;
    return $probecnt.$$;
} 
1;

