#!perl
#-T doesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::OAI::Harvester::Plus;
use Debug::Simpler 'debug', 'debug_on';
use XML::LibXML;
debug_on();


{
	my $harvester = new HTTP::OAI::Harvester::Plus(
		baseURL => 'http://spk.mimo-project.eu:8080/oai',
		resume  => 0
	);
	my $response =
	  $harvester->ListRecords( set => '78', metadataPrefix => 'mpx' );

	if ( $response && !$response->is_error ) {
		ok( ref $response eq 'HTTP::OAI::ListRecords',
			'before unwrap');
	}

	my $dom=$harvester->unwrap ($response);
	debug "dom:".$dom;

	#my $response =
	#  $harvester->GetRecord( identifier, metadataPrefix => 'oai_dc' );



	
}

