#!/usr/bin/perl

use strict;
use warnings;
use XML::LibXML;
use Getopt::Std;
getopts( 'v', our $opts = {} );
use YAML::Syck qw/LoadFile/;    #use Dancer ':syntax';
use FindBin;
use Cwd 'realpath';
use File::Spec 'catfile';
sub verbose;

#use Data::Dumper qw/Dumper/;

our $catalog = load_catalog('validate.yml');

=head1 NAME

validate.pl - Bring LibXML::Schema to the commandline

=head1 SYNOPSIS

validate.pl source.xml prefix_or_schemaLocation

=cut

#
# BASIC COMMAND INPUT SANITY
#

if ( !$ARGV[0] ) {
	print "Error: Specify source!\n";
	exit 1;
}

if ( -f !$ARGV[0] ) {
	print "Error: Source does not exist ($ARGV[0])!\n";
	exit 1;
}

if ( !$ARGV[1] ) {
	print "Error: Specify prefix or schemaLocation!\n";
	exit 1;
}

my $location = lookup( $ARGV[1] );

verbose "Check $ARGV[0]";
verbose "  against $location";

#		verbose Dumper $catalog;

#
# MAIN
#

my $doc = XML::LibXML->new->parse_file( $ARGV[0] );
my $xmlschema = XML::LibXML::Schema->new( location => $location );
eval { $xmlschema->validate($doc); };

if ($@) {
	warn "$ARGV[0] failed validation: $@" if $@;
	exit 1;
} else {
	print "$ARGV[0] validates\n";
	exit 0
}

#
# SUBS
#

=head2 my $catalog=load_catalog ($file_location);

load pseudo catalog file. A yaml file which contains info about known
uris for namespaces.

=cut


sub load_catalog {
	my $file = shift;
	my $catalog_fn =
	  realpath( File::Spec->catfile( $FindBin::Bin, '..', 'conf', $file ) );

	verbose "Trying to load $catalog_fn";
	if ( !-f $catalog_fn ) {
		print "Error: Catalog configuration not found ($catalog_fn)!";
		exit 1;
	}

	my $catalog = LoadFile($catalog_fn) or die "Cannot load config file";
	if ($catalog) {
		return $catalog;
	}
	die "Error: Loading catalog information!";
}

=head2 my $location=$self->lookup ();

Returns location uri for namespace mentioned in $ARGV[1] from the pseudo
catalog.

=cut


sub lookup {
	my $input = shift;    #prefix or location
	if ( $catalog->{ $ARGV[1] } ) {

		my $location = $input;    #prefer cache over location
		if ( $catalog->{ $ARGV[1] }->{location} ) {
			$location = $catalog->{ $ARGV[1] }->{location};
			#verbose "location: $catalog->{ $ARGV[1] }->{location}";
		}
		if ( $catalog->{ $ARGV[1] }->{cache} ) {
			$location = $catalog->{ $ARGV[1] }->{cache};
			#verbose "cache: $catalog->{ $ARGV[1] }->{cache}";
		}

		verbose "Replace $input with $location";

		return $location;
	}

}

=head2 verbose "msg";

the usual

=cut

sub verbose {
	my $msg = shift;
	if ($msg) {
		if ( $opts->{v} ) {
			print $msg. "\n";
		}
	}
}

