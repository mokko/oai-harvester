#!/usr/bin/perl

use strict;
use warnings;
use XML::LibXML;
use Getopt::Std;
getopts( 'v', my $opts = {} );

sub verbose;

#a very simple shorthand mechanism
my $catalog={
	lido=>'http://www.lido-schema.org/schema/v1.0/lido-v1.0.xsd',
	oai=>'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd',
	mpx=>'file:/home/mengel/projects/MPX/latest/mpx.xsd',
};


=head1 NAME

validate.pl - Bring LibXML::Schema to the commandline

=head1 SYNOPSIS

validate.pl source.xml schemaLocation

=cut

#
# BASIC COMMAND INPUT SANITY
#

if ( !$ARGV[0] ) {
	print "Error: Specify source!\n";
	exit 1;
}

if ( !$ARGV[1] ) {
	print "Error: Specify schemaLocation!\n";
	exit 1;
}


if ( -f !$ARGV[0] ) {
	print "Error: Source does not exist ($ARGV[0])!\n";
	exit 1;
}

if ($catalog->{$ARGV[1]}) {
	$ARGV[1]=$catalog->{$ARGV[1]};
}


verbose "Check $ARGV[0]";
verbose "  against $ARGV[1]";


#
# MAIN
#

my $doc = XML::LibXML->new->parse_file( $ARGV[0] );
my $xmlschema = XML::LibXML::Schema->new( location => $ARGV[1] );
eval { $xmlschema->validate($doc); };

if ($@) {
	warn "$ARGV[0] failed validation: $@" if $@;
} else {
	print "$ARGV[0] validates\n";
}

exit 0;

#
# SUBS
#

sub verbose {
	my $msg = shift;
	if ($msg) {
		if ( $opts->{v} ) {
			print $msg."\n";
		}
	}
}
