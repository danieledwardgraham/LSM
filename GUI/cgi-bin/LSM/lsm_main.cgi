#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Template;

$| = 1;

#my $ROOTDIR = '/home/dgraham/Apache/httpd-2.2.14/htdocs';
my $ROOTDIR = '/var/lib/openshift/56afccde89f5cf39b300003b/app-root/runtime/repo/GUI/htdocs';

#my $ROOTURL = '/home/dgraham/Apache/httpd-2.2.14/htdocs';
my $ROOTURL = '/var/lib/openshift/56afccde89f5cf39b300003b/app-root/runtime/repo/GUI/htdocs';

my $ROOTCGI = '/cgi-bin/dent/guide.pl';

my $cgi = CGI->new(  );

my ($param, $template);
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my (@hrArr, $ind, $val);
for (my $i = 0; $i < 24; $i++) {
    $ind = sprintf("%02d", $i); 
    $val = ($i == $hour) ? 1:0;
    push @hrArr, { ind => "$ind", val => "$val" };
}

my $vars = { 
    rootdir => $ROOTDIR,
    rooturl => $ROOTURL,
    rootcgi => $ROOTCGI,
    hrArr => \@hrArr,
};


$template = 'lsm_main.html';

my $tt  = Template->new(INCLUDE_PATH => ["$ROOTDIR"]);
print $cgi->header(  );
$tt->process($template, $vars)
    || die $tt->error(  );
