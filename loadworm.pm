

# AUTHOR Glenn Wood, Glenn.Wood@savesmart.com
# Copyright 1997-1998 SaveSmart, Inc.
# Copyright (c) 1997 -1998 SaveSmart, Inc. All rights reserved.
# Released under the Perl Artistic License.
# This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
#
# $Id: loadworm.pm 1.22 1998/06/18 23:00:38 Glenn dev $

use LWP::Parallel::RobotUA qw(:CALLBACK);

package LoadWorm;
use English;

$VERSION = do { my @r=(q$Id: loadworm.pm 1.22 1998/06/18 23:00:38 Glenn dev $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

if ( $OSNAME eq "MSWin32" )
{
	eval 'use Win32;'; 
	$MaxSockets = 20;
	$HostName = Win32::NodeName();
}
else
{
	eval 'use Time::HiRes;';
	$MaxSockets = 100;
	$HostName = `hostname`;
}

@EXPORT_OK = qw(GetTickCount NodeName GetConfiguration MaxSockets HostName);
$increment = 0;

# This doesn't work since Win32 is an .xs - how is this done, then?
#@ISA = qw(Win32);

1;


sub GetTickCount {

	if ( $OSNAME eq 'MSWin32' )
	{
		Win32::GetTickCount();
	}
	else
	{
		my ($sec, $us) = Time::HiRes::gettimeofday();
		return $sec * 1000 + $us / 1000;
	}
}



#
#	CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION
#	CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION
#  CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION
#  CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION  	CONFIGURATION
#
#
sub GetConfiguration { my($ConfigFile) = @_;
	my $error, $section;
	
	$WD = "." unless $WD; # The working directory.
	$MASTERDIR = $WD unless $MASTERDIR;
	$I_AM = ".*" unless $I_AM;
	
	$main::MyPort = 9676;  # This spells "WORM" in touch-tone.
	
	$main::Randomly = 0;
	
	# Read the whole .cfg file, processing each section/line.
   $error = 0;
   $section = "invalidsection";
   open CFG,  "<$ConfigFile" or die("Failed: Can't open <$ConfigFile - $!\n");
   while ( <CFG> )
   {
		chomp;
      /^\s*#/ && next; # skip '#' comments.
      /^\s*;/ && next; # skip ';' comments.
      /^\s*$/ && next; # skip blank lines.

      # Check and remember which section of the .ipd file we're in.
      /^\s*\[([^]]*)\]\s*$/ && do { $section= lc $1;
                          unless ( $section =~ /(traverse|ignore|validation|mode|proxy|noproxy|input|credentials|referersreport|slave|limit)/ )
                          {
                             print "Warning: Unrecognized section name: [$section]";
                             $section = "init";
                          };
								  for ( $section ) {
										/^traverse/	&& do
													{
														@main::TraverseURLs = ();
														last;
													};
										/^ignore/	&& do
													{	
														@main::IgnoreURLs = ();
														dbmopen %main::AlreadyIgnored, "ignores", 0666;
														%main::AlreadyIgnored = ();
														last;
													};
										/^validation/	&& do
													{	
														@main::Validations = ();
														dbmopen %main::Checks, "checks", 0666;
														%main::Checks = ();
														last;
													};
										/^referersreport/	&& do
													{	
														@main::ReferersURLs = ();
														%main::Referers = ();
														$main::Referers = 1;
														last;
													};
										/^mode/	&& do
													{
														last;
													};
										/^proxy/  && do {
														@main::Proxy = ();
														last;
													};
										/^noproxy/  && do {
														@main::NoProxy = ();
														last;
													};
										/^credentials/ && do {
														last;
													};
   									/^input/	&& do
													{
														%main::Inputs = ();
														last;
													};
										/^slave/	&& do
													{
														last;
													};
   									/^limit/	&& do
													{
														@main::Limits = ();
														last;
													};

									 # default;
										print "Warning: unrecognized section/line: $_\n";
										$section = 'invalidsection';
										$error = 1;
								  }
                          next;
                        };
      $l = $_;
		$_ = $section;
      # Make a block so we can use 'last' and 'next', switching on ($_).
      {
			/^invalidsection/ && do { last; };
         /^traverse/  && do {
							push @main::TraverseURLs, $l;
                     last;
                     };
         /^ignore/  && do {
							push @main::IgnoreURLs, $l;
                     last;
                     };
			/^validation/	&& do {
								($ky, $pckt) = split /\s*=\s*/, $l, 2;
								$subr = "Check";
								if ( $pckt =~ /(.+)::(.+)/ ) {
									$pckt = $1;
									$subr = $2;
									$pckt =~ s/\.pm$//;
									require $pckt.".pm";
								}
								else {
									$pckt = "main";
								}
								if ( def &($pckt."::".$subr) ) {
									$main::Validations{$ky} = $pckt."::".$subr;
								}
								else {
									print "Validation routine not found: $pckt.::.$subr\n";
								}
							};
         /^referersreport/  && do {
							push @main::ReferersURLs, $l;
                     last;
                     };
         /^mode/  && do {
							$_ = lc $l;
							{
								/^\s*random/ && do
								{
									$main::Randomly = 1;
									srand(time() ^ ($$ + ($$ * 2**15)) );
									last;
								};
								/^\s*(depth|recurse|timeout|verbose|noimages|load|useragent|editor|harvest)\s*=?\s*(.*)$/ && do
										{ $ENV{uc $1} = $2; last; };
								 # default;
									print "Warning: unrecognized parameter: $l\n";
									$error = 1;
							}
                    last;
                     };
         /^slave/  && do {
								&SlaveOption($l);
								last;
                     };
			/^proxy/  && do {
							push @main::Proxy, $l;
							last;
							};
			/^noproxy/  && do {
							push @main::NoProxy, $l;
							last;
							};
			/^credentials/	&& do
						{
							push @main::Credentials, $l;
							if ( defined $main::ua ) {
   							my ($netloc, $realm, $userid, $password) = split /,/, $l;
                        $main::ua->credentials($netloc, $realm, $userid, $password);
							};
							#else {	print "Credentials ignored - no current User Agent is defined.\n"; };
							last;
						};
			/^input/	&& do
						{
							my ($Murl, $Mlist) = ();
							$l =~ /\s*(\S+)\s*=\s*(\S+)/;
							unless ( $1 and $2 ) {
								print "Error in [Input], no equal sign in $l\n";
								last;
							}
							$Murl = $1;
							$Mlist = $2;
							$Murl =~ /(\S+),(\S+)/;
							unless ( $1 and $2 ) {
								print "Error in [Input], no comma in $l\n";
								last;
							}
							$main::Inputs{$Murl} = $Mlist;	# Stash that away to match/process, in IsInputMatch().
							last;
						};
			/^limit/  && do {
							push @main::Limits, $l;
							last;
							};
        }; # end of switch ($section)
   };
	close CFG;
	
   $ENV{'PERL'} = ( $OSNAME eq 'MSWin32' ) ? "C:\\Perl" : `which perl` unless defined $ENV{'PERL'};

	$ENV{'DEPTH'} = 10 unless $ENV{'DEPTH'};
	$ENV{'RECURSE'} = 1 unless $ENV{'RECURSE'};
	$ENV{'TIMEOUT'} = 120 unless $ENV{'TIMEOUT'};
}



