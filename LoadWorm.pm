=pod

=head1 NAME

LoadWorm - WebSite Stress and Validation Tool

=head1 DESCRIPTION

The LoadWorm is a tool to load a website with requests, and to record the resultant performance, from a web client's perspective.
It can also be used for various investigative purposes, such as validation of the website, or discovering all the referrers to a page, etc.

It consists of two main parts -

=over 4

=item 

LoadWorm - traverses a website, pushing all the buttons, and entering data according to specific input instructions.
It will ignore specified URL's, limit the number of times a single page is visited,
and limit the depth of the entire search.
The amount of processing required to perform all these tricks makes it too slow to act directly
as a web-loading tool, so the LoadMaster/Slave was invented to handle that job.

=item

LoadMaster/Slave - Takes a list of URL's (such as that produced by the LoadWorm),
and directs several "slaves", usually on seperate host computers, to make hits on these URL's at a tunable rate.
The "slaves" collect data on the response times (and successes/fails), which can be harvested and analyzed by the LoadMaster.

=back

The LoadWorm's operation is controlled by a configuration file.
The LoadMaster/Slave reads the same configuration file for some of it's configurables (proxy, verbosity, etc),
but is controlled mainly through a Tk based GUI.

The LoadWorm and LoadMaster/Slave works on Windows NT and Unix (tested on Solaris and Linux),
or any combination of these systems.


=head1 WEBSITE TRAVERSAL

The LoadWorm takes one or more URLs as input (specified in its configuration file, F<loadworm.cfg>).

=over 4

=item *

It follows all links, down to a configurable depth.
You may specify a different depth limit for different branches of the websiteZ<>(s).

=item *

Ignores specific links, as specified by matching the URL to regular expressions in the configuration file.

=item *

Generates INPUT data for FORMs, and traverses every possible 'SELECT'  option and 'SUBMIT' button (filterable by the 'ignore' statements in the configuration file).  (Non-multiple type of SELECT, only, in version 1.0).

=item *

The user may specify lists of values for each INPUT field of any of the FORMs.  (Text type, only, in version 1.0).

=item *

A check for a valid response can be customized for each URL (selected by a regular expression).  The validation routine can be written by the user, in Perl, and is automatically embedded into the process.

=item *

The results of a LoadWorm session are recorded in a Perl accessible database, including a list of all links
(child to parentZ<>(s)), all errors encountered, all links that were ignored, all images that were downloaded,
and the timings for every download.  The user's validation routine may also write to any of these tables.

=item *

A seperate program (LoadMaster/Slave) is a high intensity web loader that will take the route charted by the LoadWorm
and repeat the whole route, performing the request, response and validation steps
without the overhead of the route calculations inherent in the LoadWorm's configuration.

=item *

For known bugs and limitations, see L<NOTES>, at the bottom of this document.

=back

=head1 WEBSITE LOADING

Website loading is performed by the LoadMaster program. The LoadMaster runs on a master computer.
One or more LoadSlaves may run on the same computer, or different computers on the same network.
The operator can control all LoadSlaves from the LoadMaster.  He can start them, pause them,
and tune the loading rate (e.g., total hits per second).

Which URL's are actually loaded by the LoadSlaves is specified in a file named F<visits.txt>.
This is simply a list of fully specified URL's, with CGI parameters,
such as the one generated by the LoadWorm.
(The PUT method is not yet implemented here).

The LoadMaster also reads some parameters from the same configuration file that serves the LoadWorm.
It conveys these parameters to all the LoadSlaves, as well as transmitting to them the visits list.

Each LoadSlave can be configured with a simple rewrite mechanism to replace specified parameters in each URL
with a value received from a previous response.  Thus, if the website supports it's session state via a CGI parameter,
each slave can log itself in as a seperate session.  This simple mechanism can be enhanced by working over the Perl code.

Since it does not need to do any special calculations for laying down the route,
the LoadSlave can perform its operations quickly, utilizing less memory, than the LoadWorm.
This makes it possible to run several slaves on the same host computer.
Each LoadSlave must be started manually on each of the several hosts.
This simplifies the security situation, as the LoadMaster does not need to directly control anyone else's computer.
Give each LoadSlave the IP address of the LoadMaster when you start each LoadSlave.
You can start the LoadMaster first, or all the LoadSlaves first, or in any combination.

Thus, on the master host computer, use the command:

=over 4

=item

C<perl loadmaster.pl>

=back

and on each slave computer, use the command:

=over 4

=item

C<perl loadslave.pl {IP_ADDR:port_number of LoadMaster}>

=back

The IP_ADDR and port number of the LoadMaster is displayed on the LoadMaster GUI when you start it up.
The default port number of the LoadMaster is 9676 ("WORM" on a phone pad), but it's possible to 
come up differently, especially if you're running two LoadMasters on the same computer.

If the LoadMaster crashes, or is turned off, the LoadSlaves will wait patiently for it to come back up,
and each will reconnect when it does.
To finish a test, you can terminate all the LoadSlaves from the LoadMaster GUI, then terminate the LoadMaster.
The owners of the host computers you've borrowed for the load test might want to terminate the test on their computer.
They can do that by closing the LoadSlave on their computer, with no ill effect on your test except for the lost data and load.

=head1 THE CONFIGURATION FILE

The process of the LoadWorm is controlled by its configuration file.
This file is named F<loadworm.cfg>, and is found in the current working directory.
It is structured like a profile.ini file, with [section] specifying seperate sections,
and with parameters and attribute=value pairs within each section.
The sections include:

=over 4

=item [Mode]

Various modes are set here; depth, timeouts, printing, error management, etc.  See L<"[Mode]">.

=item [Traverse]

URLs listed here are the anchorZ<>(s) of the target website.  See L<"[Traverse]">.

=item [Ignore]

URLs listed here will be ignored in the traversal.  See L<"[Ignore]">.

=item [Input]

The user may specify values to be tried as input to each INPUT field in each FORM.  See L<"[Input]">.

=item [Limit]

To prevent infinite recursion, each page is visited a limited number of times (see "Recurse" in L<"[Mode]">).
In the section you can specify different limits for different pages.  See L<"[Limit]">.

=item [ReferersReport]

The webpages that link to the URLs listed here will be recorded as such in a "links" database.  See L<"[ReferersReport]">.

=item [Validation]

User customizable routines to validate the data that is returned for each URL requested.  See L<"[Validation]">.

=item [Proxy]

A URL specifying the location of the proxy for web access, if any.  See L<"[Proxy]">.

=item [NoProxy]

Domain names for which the proxy is not to be used.  See L<"[NoProxy]">.

=item [Credentials]

Authentication credentials for different net locations and realms.  See L<"[Credentials]">.

=back
These sections are explained in detail below.




=head2 [Mode]

=over 4

=item Depth = n

The loadworm will go to a maximum of 'n' links down from the anchor URL.  Depth=1 would load only the anchor page, and none of its links.

=item Random = {0,1}

If non-zero, then links will be traversed in random order, rather than in the order that they appear in the visits file.
A value of 1 will traverse all links in random order.

=item Recurse = n

Each URL will be traversed only once, unless the Recurse value is more than one.  Then each URL will be traversed the number of times specified by Recurse.

=item Timeout = secs

Specifies the timeout period for all links (in seconds).  If a link does not download completely within the time specified by this value, then it is considered a timeout error.  Default = 120 seconds.

=item NoImages = {0,1}

If non-zero, ignores all image links.

=item Verbose = {0,1}

Controls the verbosity of standard output as the loadworm processes.  Use 0 for the greatest degree of quiet. Reports on the actual performance of the loadworm are created from a database the loadworm creates.

=item Harvest = {0,1}

Turns off/on the option to harvest the results from the loadslaves.
Turning it off improves managability, since the slaves then do not need to maintain a record of the results.
This also reduces disk thrashing when multiple loadslaves are running on a host.
Harvest=0 is useful if you are monitoring the load on the server's side.

=back

=head2 [Traverse]

Specifies the URLZ<>(s) that are the anchorZ<>(s) of this test.  These are the URLZ<>(s) that are the anchorZ<>(s) of the website to be tested by this loadworm execution.

=head2 [Ignore]

A list of regular expressions which, if matching a generated URL, will cause that URL to be ignored.  For instance, .*\.netscape\.com would prevent the loadworm from traversing any link to the websites of Netscape.  Note that if the URL is explicitly listed in the [Traverse] section, then any [Ignore] match will, in its turn, be ignored.


=head2 [ReferersReport]

A list of regular expressions which, when they match a generated URL, will record in a database all webpages that link to that URL.

=head2 [Validation]

Each link can be validated with a custom Perl subroutine.
The subroutine is selected by matching the URL to a regex.
The subroutine is given the URL and the resultant webpage.
The validation routine can then verify the accuracy of the response,
and can write to the loadworm database files to record successes and/or errors.
Particularly, the I<checks> table is reserved for this.  It is tied to the hash C<%main::Checks>, which is conventionally a hash whose keys are the URLs, and whose values are whatever string the validation routine wishes to report about this URL/response pair.
A zero returned from the validation routine will tell the loadworm to ignore all links within this page.
A non-zero return will allow normal processing to continue.
For example:

=over 4

=item

C<.*=AnyURL.pm::Check>

=back

This will match any URL, and will call your subroutine, "Check", in your package "AnyURL.pm".  AnyURL.pm must be in the @INC path, and must include a package statement (e.g. package AnyURL).  See the example, AnyURL.pm. for details.

=head2 [Proxy]

A URL specifying the location of the proxy for web access, if any.

=head2 [NoProxy]

Domain names for which the proxy is not to be used.

=head2 [Credentials]

Specifies a list of user ids and passwords for each of the realms that may require authentication.
The "net location" and "realm" are seperated by a slash, then "user id" and "password" are seperated by a comma.
"Netlocation/realm" and "userid,password" are then associated with an equals sign, as in:

=over 4

=item

webdev.savesmart.com/Test Server=MyID,twi9y

=back

"webdev.savemart.com" is the net location, "Test Server" is the realm, "MyID" is the user id, and "twi9y" is the password.

=head2 [Input]

Each line specifies a list of values to be iterated across whenever a URL and INPUT line name match the specified regular expression.
The list is specified as a Perl statement suitable for I<eval>.
This feature will later allow more elaborate input generation,
but for now it allows the specification of a list of values via qw(list).  For example:

=over 4

=item

C<login.get, name = qw(test1)>

=item

C<login.get, cardnumber = qw(test1234)>

=item

C<login.get, email = NULL>

=back

The URL is matched to the first regex (before the comma),
then the NAME of the INPUT field is matched to the second regex (following the comma).
Then the list of values specified by the perl statement (following the equals sign) is iterated on the matched URL.
The special syntax of NULL is provided to allow the field to have a null value.

=head2 [Limit]

Each line specifies a regex that will match a URL, and the number of times that that URL should be visited in a LoadWorm traversal.
Thus,

=over 4

=item

C<owa/categories\.get=50>

=item

C<owa/favorite\.get=10>

=item

C<owa/cart\.get=5>

=item

C<owa/specials\.get=10>

=item

C<owa/search\.get=10>

=back

The I<owa/categories.get> CGI script will be called only 50 times in the traversal, I<owa/favorite.get> only 10,
I<owa/cart.get> only 5, etc.  The count is for all URLs that match these regular expressions.  Thus, it doesn't
matter what the CGI parameters might be to these CGI scripts, the scripts themselves will be called only as many
times as the [Limit] section specifies.

=head2 Example of a Configuration File


	[Mode]
	Harvest=1
	Depth=10
	Random=1
	Recurse=
	Timeout=30
	Verbose=0
	NoImages=0
	UserAgent=Mozilla/4.01 [en] (WinNT; I)
	Editor="C:\Program Files\TextPad\TxtPad32.exe"
	
	[Traverse]
	http://webdev.savesmart.com
	
	[Credentials]
	webdev.savesmart.com/Test Server=MyID,twi9y
	
	[Ignore]
	www\.
	www6\.
	maps\.
	justgo\.com
	netscape\.com
	/owa/go_home\.get.*
	
	[Limit]
	owa/categories\.get=50
	owa/favorite\.get=10
	owa/cart\.get=5
	owa/specials\.get=10
	owa/search\.get=10
	
	[ReferersReport]
	\.savesmart\.com:900\/
	favorite\.get
	
	[Validation]
	
	[Proxy]
	http://ssgw.savesmart.com
	
	[NoProxy]
	admin
	webdev.savesmart.com
	
	[Input]
	login.get,name=qw(test1)
	login.get,cardnumber=qw(test1234)
	login.get,email=NULL
	   
   

=head1 THE RESULTS DATABASE

B<NOTE: This information is not current, but it gives you the general idea of what is possible once we tie up a few loose ends.>

The results of a session of LoadWorm are recorded in a Perl accessible database.  Although some information is printed to standard output as the session progresses, the most interesting results should be discovered by scanning the LoadWorm database for that session.
The database consists of several hash-tied tables.  Each table is keyed by the URL associated with it, and the value will be a string representing the result.  For some of these tables, the result is an array of strings representing several interactions with that URL.  Unfortunately, Perl's built-in Tie::Hash will not record arrays in a tied table.  For these tables, the data is converted to ASCII text data and written to a sequential file.  The Perl code listed below can be used to pull this sequential file back into a hashed array in your Perl report generator.

=over 4

=item referers

This relates URLs of the website to the parent pages that contain them.  @referers{$childURL} is an array of URLs of pages that link to $childURL.  (This table does not include images.  These are recorded in the images table.  It does include all ignored URLs.)  Note: this file is not a hash-tied database file, but a sequential file containing data that can be imported into a hashed table with the Perl code listed below (tbl2hash.pl).

=item errors

This is a list of all the URLs that failed to download.  $errors{$URL} is the error message associated with the attempt to download $URL.

=item ignores

This is a list of all URLs that were encountered in the website, but were ignored because they match some regular expression in the [Ignore] section of the configuration file.  $ignore{$URL} is the regular expression that caused $URL to be included in this list.

=item timings

This text file records the time of each request, and the time of completion of that request.  Each record consists of two (or more) lines.  The first line contains the URL.  The second line contains the start time, the finish time, and the size in a string like (hh:mm:ss.hh,hh:mm:ss.hh size).  The size might be the string "FAILED", instead, indicating that the request failed.  Then, the following lines will contain the reason for the failure, until a line containing a copy of the original "FAILED" line.  Thus, timings includes the time for failed downloads as well as successful ones.

=item checks

This table is written by the user-customized validation routineZ<>(s).

   tbl2hash.pl

	%Linkages = ();
	open TBL, "<linkages";
	while ( <TBL> )  {
		if ( $_ !~ /^\s/ )  {
			$ky = $_;
		}
		else {
			s/^\s*//;
			push @{  $Linkages{$ky}  }, $_;
		}
	}

=back


=head1 NOTES

=over 4

=item *

Watch for #tag in CGI function names.

=item *

To specify an image click position, define the key as the image name, and the value as "image.x=x&image.y=y".

=item *

Due to our as yet incomplete control of the TCP/IP layer in this program,
we can not actually duplicate the conditions of modem (or any other low data rate) access to the website.
Some conditions of our multiple client, high speed data transfers will be different than when many clients
are accessing the website at lower speeds.

=item *

Each loadslave is limited to twenty-three simultaneous connections.
Subsequent connections fail when trying to register (or is it when trying to connect?).
This is a limitation imposed by the operating system when the Perl executable was compiled.
We have hard-coded a governor at 20 connections to avoid this limit.
Multiple instances may be run on a single host, but each one has the same limit.

=item *

The LoadMaster can not accept connections from more that 28 LoadSlaves (for the same reason).

=item *

Consequently, the upper limit to the loadtest is 28x23, or 644 simultaneous connections to the web-server.
Is there anyway to increase this?
We can run multiple loadmasters, I suppose;
does it make sense, then, to have a super-loadmaster, or perhaps loadslave monitors,
so that the load master talks to one slave monitor, which deals with the (up to twenty-eight) loadslaves on it's own NT?
Etc.

=back

=head1 PREREQUESITES

These are the versions of Perl modules under which LoadWorm is known to work.
It may be just fine with earlier or later versions.

=over 4

=item *

Perl 5.004 (thanks, Larry!)

=item *

F<LWP> from libwww-perl-5_20

=item *

F<LWP::Parallel> from ParallelUserAgent-v2_31 (a special thanks to Marc Langheinrich!)

=item *

F<Tk> from Tk402_003

=item *

F<Time::Local> and F<Time::HiRes> for Unix OS.

=item *

F<Win32> for Win32 OS.

=item *

And various core Perl modules, including 
F<English>,
F<File::Path>,
F<File::Copy>,
F<Socket>,
F<Carp>,
F<FileHandle>,
and F<Sys::Hostname>.

=back



=head1 AUTHOR

Glenn Wood, C<glenwood@alumni.caltech.edu>.

Copyright 1997-1998 SaveSmart, Inc.

Released under the Perl Artistic License.

$Id: LoadWorm.pm,v 1.1.1.1 2001/05/19 02:54:40 Glenn Wood Exp $

=cut

use LWP::Parallel::RobotUA qw(:CALLBACK);

package LoadWorm;
use English;

$VERSION = do { my @r=(q $Name:  $ =~ /\d+/g ); sprintf "%d."."%02d"x$#r,@r }; 

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



