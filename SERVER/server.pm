# Class : Server
# This module implements a class for processing ETL requests
# v.1.0, Dan Graham, 10/17/2009
#
package server;

use strict;
use Carp;
use Config;
use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT);
use IPC::Semaphore;
use statPull;
use dbETL;
use dbAgg;
use Data::Dumper;

my $HEADER;

sub new {
    my $class = shift;
    my $args = shift;
    my $self = { };
    $self->{"pid"} = undef;
    $self->{"sem"} = IPC::Semaphore->new(IPC_PRIVATE, 1, S_IRUSR | S_IWUSR | IPC_CREAT) || die "semget: $!\n";
    $self->{"sem2"} = IPC::Semaphore->new(IPC_PRIVATE, 1, S_IRUSR | S_IWUSR | IPC_CREAT) || die "semget: $!\n";
    $self->{"receive"} = statPull->new($args);
    $self->{"database"} = dbETL->new($args);
    $self->{"database2"} = dbAgg->new($args);
    return bless($self, $class);
}

sub start {
    my $self = shift;
    my $pid;
    if (defined($self->{"pid"})) {
        $self->logmsg("error: server already started - stop server first");
        return;
    }
    $self->{"sem"}->setval(0, 1) || die "sem->setval: $!\n";
    $self->{"sem2"}->setval(0, 1) || die "sem->setval: $!\n";
    $self->{"database2"}->start($self);
    if (!defined($pid = fork)) {
        $self->logmsg("Error: cannot fork: $!");
        return;
    } elsif ($pid) {
        $self->logmsg("starting server with pid $pid");
        $self->{"pid"} = $pid; 
        return;
    }
    local $SIG{'TERM'} = sub {
        $self->logmsg("stopping server...");
        $self->{"pid"} = undef;
        $self->{"sem"}->remove() or $self->logmsg("Error: Could not remove semaphore: $!\n");
        $self->{"sem2"}->remove() or $self->logmsg("Error: Could not remove semaphore: $!\n");
        exit(0);
    };
    $self->receiveStats();
}

sub stop {
    my $self = shift;
    if (!defined($self->{"pid"})) {
        return;
    }
    $self->{"database2"}->stop();
    my $i = 0;
    my (%signo, @signame);
    foreach my $name (split(' ', $Config{sig_name})) {
        $signo{$name} = $i;
        $signame[$i] = $name;
        $i++;
    }
    if (kill($signo{TERM}, $self->{"pid"}) < 1) {
        $self->logmsg("error: could not stop server");
        return;
    }
    return;
}

sub procStats {
    my $self = shift;
    my $xml = shift;
    $xml = "<root>".$xml."</root>";
    my $stats = $self->_ParseXML($xml);
    $self->{"sem"}->op(0, -1, 0) or $self->logmsg("Semaphore error: $!\n");
    $self->{"database"}->connect();
    $self->dbUpdate([ ], $stats, "LINUX", undef, { }, { }, 0, { }, ""); 
    $self->{"database"}->disconnect();
    $self->{"sem"}->op(0, 1, 0) or $self->logmsg("Semaphore error: $!\n");
    return;
}

sub receiveStats {
   my $self = shift;
   $self->{"receive"}->pull($self);
   return;
} 
     
sub _ParseXML {
    my ($xml) = @_;
#    $xml =~ s/\n//g;
    $xml =~ s/\<\!\[CDATA\[(.*?)\]\]\>/&_cdatasub($1)/egs;
    $xml =~ s/\<\!\-\-.*?\-\-\>//gs;
    $xml =~ s/\<\?xml.*?\?\>//gs;
    $xml =~ s/\<\?[^\>]*?\?\>//gs;
    $xml =~ s/\<\!\-\-[^\>]*?\-\-\>//gs;
    $xml =~ s/\<\!ELEMENT[^\>]*?\>//gs;
    $xml =~ s/\<\!ENTITY[^\>]*?\>//gs;
    $xml =~ s/\<\!ATTLIST[^\>]*?\>//gs;
    $xml =~ s/\<\!DOCTYPE[^\>]*?\>//gs;
    my $rethash = ();
    my @retarr;
    my $firsttag = $xml;
    my ( $attr, $innerxml, $xmlfragment );
    $firsttag =~ s/^[\s\n]*\<([^\s\>\n\/]*).*$/$1/gs;
    $firsttag =~ s/\\/\\\\/gs;
    $firsttag =~ s/\*/\\\*/gs;
    $firsttag =~ s/\|/\\\|/gs;
    $firsttag =~ s/\$/\\\$/gs;
    $firsttag =~ s/\?/\\\?/gs;
    $firsttag =~ s/\{/\\\{/gs;
    $firsttag =~ s/\}/\\\}/gs;
    $firsttag =~ s/\(/\\\(/gs;
    $firsttag =~ s/\)/\\\)/gs;
    $firsttag =~ s/\+/\\\+/gs;
    $firsttag =~ s/\[/\\\[/gs;
    $firsttag =~ s/\]/\\\]/gs;
    $firsttag =~ s/\./\\\./gs;
    $firsttag =~ s/\^/\\\^/gs;
    $firsttag =~ s/\-/\\\-/gs;

    if ( $xml =~ /^[\s\n]*\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s )
    {
        $attr        = $1;
        $innerxml    = $2;
        $xmlfragment = $3;
        $attr =~ s/\>$//gs;
    }
    else {
      if ( $xml =~ /^[\s\n]*\<${firsttag}(\/\>|[\s\n][^\>]*\/\>)(.*)$/s ) {
        $attr = $1;
        $innerxml = "";
        $xmlfragment = $2;
      } else {
        if (!ref($xml)) {
            $xml = _entity($xml);
            $xml =~ s/0x0CDATA0x0(\d+?)0x0/&_cdatasubout($1)/egs;
        }
        return $xml;
      }
    }
    my $ixml = $innerxml;
    while ($ixml =~ /^.*?\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)$/s) {
        $ixml = $2;
        $innerxml .= "</${firsttag}>";
        if ($xmlfragment =~ /^(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s) {
            my $ix = $1;
            $innerxml .= $ix;
            $ixml .= $ix; 
            $xmlfragment = $2;
        } else {
            die "Invalid XML innerxml: $innerxml\nixml: $ixml\nxmlfragment: $xmlfragment\n";
        }
    }        
    my $nextparse = _ParseXML($innerxml);
    $rethash->{&_unescp($firsttag)} = $nextparse;
    my @attrarr;
    while ( $attr =~ s/^[\s\n]*([^\s\=\n]+)\s*\=\s*(\".*?\"|\'.*?\')(.*)$/$3/gs ) {
        my ($name, $val) = ($1, $2);
        $val =~ s/^\'(.*)\'$/$1/gs;
        $val =~ s/^\"(.*)\"$/$1/gs;
        push @attrarr, $name;
        push @attrarr, _entity($val);
    }
    my $attrcnt = 0;
    while ( my $val = shift(@attrarr) ) {
        $rethash->{ "$val" . "_".&_unescp(${firsttag})."_" . $attrcnt . "_attr" } = shift(@attrarr);
    }
    my $retflag = 0;
    my ( $xmlfragment1, $xmlfragment2 );
    my %attrhash;
    $attrcnt++;
    while (1) {
        if ( $xmlfragment =~
            /^(.*?)\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s )
        {
            if ( !$retflag ) {
                push @retarr, $nextparse;
            }
            $retflag      = 1;
            $xmlfragment1 = $1;
            $attr         = $2;
            $innerxml     = $3;
            $xmlfragment2 = $4;
        } else {
          if ( $xmlfragment =~ /^(.*?)\<${firsttag}(\/\>|[\s\n][^\>]*\/\>)(.*)$/s ) {
            if ( !$retflag ) {
                push @retarr, $nextparse;
            }
            $retflag      = 1;
            $xmlfragment1 = $1;
            $attr = $2;
            $innerxml = "";
            $xmlfragment2 = $3;
          } else {
            last;
          }
        }
        $attr =~ s/\>$//gs;
        my %opening = ( );
        my %closing = ( );
        my $frag = $xmlfragment1;
        while ($frag =~ /^(.*?)\<([^\s\n\/]+)[^\/]*?\>(.*)$/s) {
            my $tg = $2;
            $frag = $3;
            $opening{$tg}++;
        }
        my $frag = $xmlfragment1;
        while ($frag =~ /^(.*?)\<\/([^\s\n]+)\>(.*)$/s) {
            my $tg = $2;
            $frag = $3;
            $closing{$tg}++;
        }
        my $flag = 0;
        foreach my $k (keys %opening) {
            if ($opening{$k} > $closing{$k}) {
                $xmlfragment = $xmlfragment1 . "<${firsttag}0x0 ${attr}>${innerxml}</${firsttag}0x0>". $xmlfragment2;
                $flag = 1;
                last;
            }
        }
        next if ($flag);
        my $ixml = $innerxml;
        while ($ixml =~ /.*?\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)$/s) {
            $ixml = $2;
            $innerxml .= "</${firsttag}>";
            if ($xmlfragment2 =~ /(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s) {
                my $ix = $1;
                $innerxml .= $ix;
                $ixml .= $ix;
                $xmlfragment2 = $2;
            } else {
                die "Invalid XML";
            }
        }        
        $xmlfragment  = $xmlfragment1 . $xmlfragment2;
        while ( $attr =~ s/^[\s\n]*([^\s\=\n]+)\s*\=\s*(\".*?\"|\'.*?\')(.*)$/$3/gs ) {
            my ($name, $val) = ($1, $2);
            $val =~ s/^\'(.*)\'$/$1/gs;
            $val =~ s/^\"(.*)\"$/$1/gs;
            push @attrarr, $name;
            push @attrarr, _entity($val);
        }
        while ( my $val = shift(@attrarr) ) {
                $rethash->{ "$val" . "_".&_unescp(${firsttag})."_" . $attrcnt . "_attr" } = shift(@attrarr);
        }
        $attrcnt++;
        $nextparse    = _ParseXML($innerxml);
        push @retarr, $nextparse;
    }
    if (@retarr) {
        $rethash->{_unescp($firsttag)} = \@retarr;
    }
    $xmlfragment =~ s/${firsttag}0x0/${firsttag}/gs;
    my $remainderparse = _ParseXML($xmlfragment);
    my $attrcnt;
    my $attrfrag;
    if ( ref($remainderparse) eq "HASH" ) {
        foreach ( keys %{$remainderparse} ) {
            $rethash->{&_unescp($_)} = $remainderparse->{&_unescp($_)};
        }
    }
    if ( keys %{$rethash} ) {
        return $rethash;
    }
    else {
        return undef;
    }
}

sub dbUpdate {
    my $self = shift;
    my $writestackArg = shift;
    my $obj = shift;
    my $curtag = shift;
    my $time = shift;
    my $val = shift;
    my $desc = shift;
    my $arrcnt = shift;
    my $topobj = shift;
    my $topkey = shift;
    my $writestackStackArg = shift;
    my $writestack2Arg = shift;
    my $keyStackArg = shift;
    my $keystackStackArg = shift;
    my $lastKey = shift || 1;
    my %counterAttr;
    my (@stackCopy, $lastKey);
    my $repeatKeyLevel = 0;
    my $copyCnt = 0;
    my @writestackArr = map {$_;} @{$writestackArg};
    my $writestack = \@writestackArr;
    my @writestackStackArr = map {$_;} @{$writestackStackArg};
    my $writestackStack = \@writestackStackArr;
    my @writestack2Arr = map {$_;} @{$writestack2Arg};
    my $writestack2 = \@writestack2Arr;
    my @keyStackArr = map {$_;} @{$keyStackArg};
    my $keyStack = \@keyStackArr;
#    my $keyStack = $keyStackArg;
    my @keystackStackArr = map {$_;} @{$keystackStackArg};
    my $keystackStack = \@keystackStackArr;
    if (ref($obj) eq "ARRAY") {
        $arrcnt = 0;
        foreach my $subobj (@{$obj}) {
            $self->dbUpdate($writestack, $subobj, $curtag."Item", $time, $val, $desc, $arrcnt++, $topobj, $topkey, $writestackStack, $writestack2, $keyStack, $keystackStack, $lastKey);
        }
    } else {
        if (ref($obj) eq "HASH") {
            my @sortarr = sort {
                my ( $s, $s2 );
                if ( defined( $obj->{ "key" . "_$a" . "_attr" } ) ) {
                    $s = $obj->{ "key" . "_$a" . "_attr" };
                }
                else {
                    $s = $a;
                }
                if ( defined( $obj->{ "key" . "_$b" . "_attr" } ) ) {
                    $s2 = $obj->{ "key" . "_$b" . "_attr" };
                }
                else {
                    $s2 = $b;
                }
                if (defined($obj->{"counter" . "_$a" . "_attr"})) {
                    $s += 2000;
                }
                if (defined($obj->{"counter" . "_$b" . "_attr"})) {
                    $s2 += 2000;
                }
                if ((ref($obj->{"$a"}) eq "HASH") || (ref($obj->{"$a"}) eq "ARRAY")) {
                    $s += 1000;
                }
                if ((ref($obj->{"$b"}) eq "HASH") || (ref($obj->{"$b"}) eq "ARRAY")) {
                    $s2 += 1000;
                }
                $s <=> $s2;
            } ( keys %{$obj} );
            my $counterFlag = 0;
            my $newTime;
            my $attr;
            my $d;
            my $prevSeq = -100;
            my $arrpost = $arrcnt;
            $arrpost = "" if ($arrcnt == 0);
            foreach my $key (@sortarr) {
                if (ref($topobj) eq "HASH" && defined($newTime = $topobj->{ "time" . "_$topkey". $arrpost . "_attr" })) {
                    $time = $newTime;
                }
                if (defined($newTime = $obj->{ "time" . "_$key" . "_attr" })) {
                    $time = $newTime;
                }
                if (defined($attr = $obj->{ "counter" . "_$key". "_attr"})) {
                    $counterFlag = 1;
                    $counterAttr{"$key"} = $attr;
                }
                if (defined($d = $obj->{ "$key" . "_$key" . "_attr"})) {
                    $desc->{"$key"} = $d;
                }
                if ($prevSeq == $obj->{ "key" . "_$key" . "_attr"}) {
                    if ($repeatKeyLevel == 0) {
                        $stackCopy[$copyCnt] = [ ];
                        foreach (@$keyStack) {
                            push @{$stackCopy[$copyCnt]}, $_;
                        }
                        push @{$keystackStack}, $stackCopy[$copyCnt++];
                        $lastKey = pop @{$keyStack};
                        $lastKey++ if ($key !~ /Item$/ && $key !~ /attr$/);
                        push @{$keyStack}, $lastKey if ($key !~ /Item$/ && $key !~ /attr$/);
                    } 
                    $repeatKeyLevel = 1;
                    $stackCopy[$copyCnt] = [ ];
                    foreach (@$writestack) {
                        push @{$stackCopy[$copyCnt]}, $_;
                    }
                    push @{$writestackStack}, $stackCopy[$copyCnt++];
                    pop @{$writestack};
#                    $lastKey = pop @{$keyStack};
#                    push @{$keyStack}, $lastKey + 1;
                    $stackCopy[$copyCnt] = [ ];
                    foreach (@$keyStack) {
                        push @{$stackCopy[$copyCnt]}, $_;
                    }
                    push @{$keystackStack}, $stackCopy[$copyCnt++];
                    $lastKey = pop @{$keyStack};
                } else {
                    foreach (@{$writestackStack}) {
                        push @{$_}, $key if ($key !~ /Item$/ && $key !~ /attr$/);
                    }
                    $lastKey = $keyStack->[@$keyStack - 1] || 0;
                    foreach (@{$keystackStack}) {
                        push @{$_}, $lastKey if ($key !~ /Item$/ && $key !~ /attr$/);
                    }
#                    push @$keyStack, $lastKey + 1;
                    if ($repeatKeyLevel > 0) {
                        $stackCopy[$copyCnt] = [ ];
                        foreach (@$writestack) {
                            push @{$stackCopy[$copyCnt]}, $_;
                        }
                        push @{$writestackStack}, $stackCopy[$copyCnt++];
#                        $lastKey = pop @{$keyStack};
#                        push @{$keyStack}, $lastKey + 1;
                        $stackCopy[$copyCnt] = [ ];
                        foreach (@$keyStack) {
                            push @{$stackCopy[$copyCnt]}, $_;
                        }
                        push @{$keystackStack}, $stackCopy[$copyCnt++];
                    }
                    $repeatKeyLevel = 0;
                }
                if (defined($obj->{ "key" . "_$key" . "_attr"})) {
                    $prevSeq = $obj->{ "key" . "_$key" . "_attr"};
                } 
                push @{$writestack}, $key if ($key !~ /Item$/ && $key !~ /attr$/);
                $lastKey++ if ($key !~ /Item$/ && $key !~ /attr$/);
                push @{$keyStack}, $lastKey if ($key !~ /Item$/ && $key !~ /attr$/);
                push @{$writestack2}, $key if ($key !~ /Item$/ && $key !~ /attr$/);
                $val->{"$key"} = $self->dbUpdate($writestack, $obj->{"$key"}, $key, $time, $val, $desc, 0, $obj, $key, $writestackStack, $writestack2, $keyStack, $keystackStack, $lastKey);
            }
#            if ($repeatKeyLevel >= 0) {
#                $stackCopy[$copyCnt] = [ ];
#                foreach (@$writestack) {
#                    push @{$stackCopy[$copyCnt]}, $_;
#                }
#                push @{$writestackStack}, $stackCopy[$copyCnt++];
#                $lastKey = pop @{$keyStack};
#                push @{$keyStack}, $lastKey + 1;
#               $stackCopy[$copyCnt] = [ ];
#               foreach (@$keyStack) {
#                   push @{$stackCopy[$copyCnt]}, $_;
#               }
#               push @{$keystackStack}, $stackCopy[$copyCnt++];
#           }
            my ($i, $topid, $ws, $ks, @topoArr, $t);
            if ($counterFlag) {
                my $dbData = { };
                my $dbDataTopo = [ ];
                my $topoMap = { };
                foreach my $cnt (keys %counterAttr) {
                    $dbData->{"counterNm"} = $cnt;
                    $dbData->{"counterVal"} = $val->{"$cnt"};
                    $dbData->{"counterAttr"} = $counterAttr{"$cnt"};
                    $dbData->{"counterDesc"} = $desc->{"$cnt"};
                    $time =~ s/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/$1-$2-$3 $4:$5:$6/g;
                    $dbData->{"time"} = $time;
                    foreach $i (@{$writestack2}) {
                        push @{$dbDataTopo}, { 'key' => "$i", 'val' => $val->{"$i"}, 'desc' => $desc->{"$i"} } if (!defined($counterAttr{"$i"}));
                    }
                    $dbData->{"topo"} = $dbDataTopo;
                    $topid = $self->{"database"}->updateTbls($dbData);
                    $dbData = { };
                    $dbDataTopo = [ ];
                    print Dumper($writestackStack);
                    print Dumper($keystackStack);
                    foreach $ws (@$writestackStack) {
                        @topoArr = ( );
                        foreach $i (@{$ws}) {
                            push @{$dbDataTopo}, { 'key' => "$i", 'val' => $val->{"$i"}, 'desc' => $desc->{"$i"} } if (!defined($counterAttr{"$i"}));
                        }
                        $dbData->{"topo"} = $dbDataTopo;
                        $topoMap->{"countTopId"} = $topid;
                        $ks = shift @$keystackStack;
                        for ($i = 1; $i <= @$ks; $i++) {
                            $topoMap->{"key$i"} = $ks->[$i-1];
                        }
                        foreach $t (@{$dbData->{"topo"}}) {
                            push @topoArr, $t;
                            return if (($self->{"database"}->registerTopo(\@topoArr, $topoMap)) < 0);
                        }
                        $topoMap = { };
                        $dbData = { };
                        $dbDataTopo = [ ];
                    }
                    $dbData = { };
                    $dbDataTopo = [ ];
                }
            }
            return undef;
        } else {
            return $obj;
        }
    }
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
    return;
}

1;
