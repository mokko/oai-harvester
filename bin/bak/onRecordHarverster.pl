#!/usr/bin/perl
# ABSTRACT: trying out HTTP::OAI::Harvester's onRecord
# PODNAME: onRecordHarvester.pl
# try to save memory by using onRecord
# always unwraps

use strict;
use warnings;
use HTTP::OAI;
use Getopt::Std;

#use utf8; #not sure it is still necessary

#use HTTP::OAI::Harvester
use YAML::Syck qw/LoadFile/;
use Pod::Usage;
use XML::LibXML::XPathContext;

#only for debugging
use Data::Dumper qw (Dumper);

sub verbose;
our $harvest;         #the complete document
our $harvest_xpc;     #xpath context
our @harvest_root;    #root element

=head1 SYNOPSIS

  harvest.pl [ -v ] conf.yml

  Always unwrapps, always resume, never validates. Just testing.

=cut

getopts( 'hv', our $opts = {} );
pod2usage() if ( $opts->{h} );

our $config = configSanity( $ARGV[0] );

my $harvester = HTTP::OAI::Harvester->new(
	resume  => 0,
	baseURL => $config->{baseURL},
);

#act on verb
my $cb = sub {

	#verbose "Enter onRecord";
	my $record = shift;
	if ( $record->metadata ) {

		#first time copy complete document
		if ( !$harvest ) {
			$harvest     = $record->metadata->dom;
			$harvest_xpc = _registerNS($harvest);
			@harvest_root =
			  $harvest_xpc->findnodes('/md:metadata/mpx:museumPlusExport');
			$harvest->setDocumentElement( $harvest_root[0] );

			#verbose $harvest->toString;
			#exit;
		} else {

			#every other time: add records
			$harvest = addRecords( $record->metadata );
		}

	}
};

sub addRecords {
	my $record = shift or die "Error!";
	$record = $record->dom;    # now XML::LibXML::Document object
	verbose "Enter addRecords ($record)";
	my $record_xpc = _registerNS($record);

	#correct root element HTTP::OAI bug in v3.25
	my @record_root =
	  $record_xpc->findnodes('/md:metadata/mpx:museumPlusExport');
	if ( $harvest_root[0] ) {
		$record->setDocumentElement( $harvest_root[0] );
	}

	#verbose "RECORD" . $record->toString;

	#i guess this can go wrong if there is no first item.
	my @new = $record_xpc->findnodes("/mpx:museumPlusExport/*");

	#I could also use firstChild. It would be a bit more generic

	foreach my $new (@new) {
		my $new_xpc = _registerNS($new);

		#insert only if does not yet exist

		my $idName;
		my $type = $new->nodeName;

		#verbose "NODENAME: $nodeName";
		#some UTF problem
		if ( $type eq 'sammlungsobjekt' ) {
			$idName = 'objId';
		} elsif ( $type eq 'multimediaobjekt' ) {
			$idName = 'mulId';
		} else {
			$idName = 'kueId';
		}

		my $newId = $new->findvalue( '@' . $idName );
		verbose " NEWID $idName $newId ";

		my $xpath = "mpx:/mpx:museumPlusExport/mpx:$type";
		$xpath .= "[\@$idName = '$newId' ]";
		verbose "XPATH:$xpath";
		my $node = $harvest->find($xpath);

		if ( !$node ) {
			verbose "item with this id NOT exists yet";

			#my @first =
			#  $harvest_xpc->findnodes( " / mpx
			#: museumPlusExport / mpx : $type " . '[1]' );
			#$harvest_root[0]->insertBefore( $new, $first[0] );
		}

	}

	#print $harvest->toString;
	exit 1;

}

my $response = $harvester->ListRecords(
	onRecord       => $cb,
	metadataPrefix => 'mpx'
);

if ( $response->is_error ) {
	print $response->code . " " . $response->message, " \n ";
	exit 1;
}

#
# SUBS
#

=func $doc=_registerNS ($doc);

=cut

sub _registerNS {
	my $doc = shift or die " Can't registerNS ";
	my $xpc = XML::LibXML::XPathContext->new($doc);

	#should configurable, of course $self->{nativePrefix}, $self->{nativeURI}
	$xpc->registerNs( 'mpx', 'http://www.mpx.org/mpx' );
	$xpc->registerNs( 'md',  'http://www.openarchives.org/OAI/2.0/' );

	return $xpc;
}

sub configSanity {
	my $configFn = shift;

	if ( !$configFn ) {
		print " Error : Specify config file !\n ";
		exit 1;
	}

	if ( !-f $configFn ) {
		print " Error : Specified file does not exist !\n ";
		exit 1;
	}

	verbose " About to load config file($configFn) ";

	my $config = LoadFile($configFn) or die " Cannot load config file ";

	#command line overwrites config file
	if ( $opts->{o} ) {
		$config->{output} = $opts->{o};
	}

	#ensure that there is the output key
	if ( $config->{output} ) {
		verbose " Output : " . $config->{output};
	} else {

		#init output even if empty to avoid uninitialized warning
		$config->{output} = '';
		verbose " Output : STDOUT ";
	}

	#if ( !$config->{resume} ) {
	#	$config->{resume} = 'false';
	#}
	#verbose " Resume( conf file ) : $config->{resume} ";

	return $config;
}

=head2 verbose " message ";

Print message to STDOUT if script is run with -v options.

=cut

sub verbose {
	my $msg = shift;
	if ($msg) {
		if ( $opts->{v} ) {
			print $msg. " \n ";
		}
	}
}

