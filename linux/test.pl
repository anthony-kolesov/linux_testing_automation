#!/usr/bin/perl

use strict;
use warnings;
use Env;

my $hostname = `hostname`;
chomp ($hostname);

my $logfile = $ENV{WORKSPACE}."/".$ENV{BUILD_NUMBER}."/build.log";
open (LOG,">$logfile")||die("Couldn't open log file $logfile\n");

print LOG "Running on host $hostname\n"; 
print LOG "Creating locx on $ENV{WORKSPACE}/$ENV{BUILD_NUMBER}/alldone\n";
system("touch $ENV{WORKSPACE}/$ENV{BUILD_NUMBER}/alldone");

