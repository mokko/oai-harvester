#!/usr/bin/perl

use strict;
use warnings;
use XML::Schematron;

#I cannot get this module to work. I might just use the xsl provided by
#http://www.schematron.com/
#in simple cases, it seems I need to apply only one xsl on a tron.xml
#to get a xslt which in turn i need to apply to xml

=head1 NAME

tron.pl - bring XML::Schematron to command line

=head1 SYNOPSIS

tron.pl source.xml schematron.xml

=cut

#
# simple sanity
#

if ( !$ARGV[0] ) {
	print "Error: Need a source document!";
}

if ( !-f $ARGV[0] ) {
	print "Error: Specified source document does not exist ($ARGV[0])!";
}

if ( !$ARGV[1] ) {
	print "Error: Need a schematron!";
}

if ( !-f $ARGV[1] ) {
	print "Error: Specified schematron does not exist ($ARGV[1])!";
}

#
# MAIN
#

my $pseudotron =
  XML::Schematron->new_with_traits( traits => ['LibXSLT'], schema => $ARGV[1] );

print 'pseudotron'.$pseudotron->dump_xsl;

my @messages = $pseudotron->verify( $ARGV[0] ) or die "cannot verify";



foreach my $msg (@messages) {
	print "MSG:$msg\n";
}


#
# SUBS
#
