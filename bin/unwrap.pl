#!/usr/bin/perl
# ABSTRACT: unwrap metadata inside of a OAI response  (ListRecord, GetRecord)
# PODNAME: unwrap.pl

use strict;
use warnings;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
use HTTP::OAI::Harvester::Plus;
use Getopt::Std;
use Debug::Simpler 'debug', 'debug_on';
getopts( 'hv', my $opts = {} );

=head1 SYNOPSIS

unwrap.pl -v input.oai.xml output.xml

=cut

#
# General Sanity
#

if ( !$ARGV[0] ) {
	print "Error: You did not specify source file!\n";
	exit 1;
}

if ( !-f $ARGV[0] ) {
	print "Error: Cannot find source file\n";
	exit 1;
}

if ( !$ARGV[1] ) {
	debug "You didnot specify output; will use STDOUT!";
}

#
# MAIN
#

my $source = XML::LibXML->load_xml( location => $ARGV[0] );
my $harvester = new HTTP::OAI::Harvester::Plus(baseURL=>'test');
my $dom=$harvester->unwrap ($source);
outputDOM ($dom);
exit 1;


#
# SUBS
#

=func outputDOM ($dom);

outputs DOM either to file (if ARGV[1] defined) or to STDOUT/

=cut

sub outputDOM {
	my $result=shift or return;
	if ($ARGV[1]) {
		$result->toFile ($ARGV[1], '1') or die "Cannot write $ARGV[1]";
		#1 is a readable format, use 0 to save space
		#$stylesheet->output_file($result, $ARGV[1]) or die "Cannot write file ($ARGV[1])";
	} else {
		print $result->toString;
	}
}

