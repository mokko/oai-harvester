#!/usr/bin/perl

use strict;
use warnings;
use XML::LibXML;
use XML::LibXSLT;
use FindBin;
use Cwd 'realpath';
use Getopt::Std;
getopts( 'hv', my $opts = {} );

sub verbose;

=head1 NAME

unwrap.pl - Little script that "unwraps" the metadata inside of a OAI response
 (ListRecord, GetRecord)

=head1 SYNOPSIS

unwrap.pl -o file.xml -v file.oai.xml

=cut

=head2 verbose "message";

Print message to STDOUT if script is run with -v options.

=cut

#
# General Sanity
#

my $XSL = $FindBin::Bin . '/../xslt/unwrap.xsl';
$XSL = realpath($XSL);
verbose "Looking for unwrapper at $XSL";

if ( !-f $XSL ) {
	print "Error: $XSL does not exist";
	exit 1;
}

if ( !$ARGV[0] ) {
	print "Error: You did not specify source file!\n";
	exit 1;
}

if ( !-f $ARGV[0] ) {
	print "Error: Cannot find source file\n";
	exit 1;
}

if ( !$ARGV[1] ) {
	verbose "You didnot specify output, so will be using STDOUT!";
}

#
# MAIN
#

my $xslt = XML::LibXSLT->new();
my $source = XML::LibXML->load_xml( location => $ARGV[0] );
my $style_doc =
  XML::LibXML->load_xml( location => $XSL, no_cdata => 1 );
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $result = $stylesheet->transform($source) or die "Problems!".@!;
#print "result:".$result->toString."\n";
output ($result);
exit;


#
# SUBS
#

sub output {
	my $result=shift;
	if ($ARGV[1]) {
		$result->toFile ($ARGV[1], '1') or die "Cannot write $ARGV[1]";
		#1 is a readable format, use 0 to save space
		#$stylesheet->output_file($result, $ARGV[1]) or die "Cannot write file ($ARGV[1])";
	} else {
		print $result->toString;
	}
}

sub verbose {
	my $msg = shift;
	if ($msg) {
		if ( $opts->{v} ) {
			print $msg. "\n";
		}
	}
}
