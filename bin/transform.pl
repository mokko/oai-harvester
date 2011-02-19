#!/usr/bin/perl

use strict;
use warnings;
use XML::LibXSLT;
use XML::LibXML;
sub verbose;

=head1 NAME

transform.pl - Small script that brings libXML's xslt to the commandline

=head1 SYNOPSIS

transform.pl source.xml stylesheet.xsl output.xml

=cut

#
# Commandline input: sanity
#

if ( !$ARGV[0] ) {
	print "Error: Specify source!\n";
	exit 1;
}

if ( !$ARGV[1] ) {
	print "Error: Specify stylesheet!\n";
	exit 1;
}

if ( !$ARGV[2] ) {
	print "Error: Specify output!\n";
	exit 1;
}

if ( !-f $ARGV[0] ) {
	print "Error: Source does not exist ($ARGV[0])!\n";
	exit 1;
}

if ( -f !$ARGV[1] ) {
	print "Error: Stylesheet does not exist ($ARGV[1])!\n";
	exit 1;
}

if ( -f !$ARGV[2] ) {
	print "Warring: Output exists already, will be overwritten ($ARGV[2])!\n";
	exit 1;
}

#
# MAIN
#

my $xslt       = XML::LibXSLT->new();
my $source     = XML::LibXML->load_xml( location => $ARGV[0] );
my $style_doc = XML::LibXML->load_xml(location=>$ARGV[1], no_cdata=>1);
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $result = $stylesheet->transform($source);

#
# SAVE TO FILE
#
$stylesheet->output_file($result, $ARGV[2]);


