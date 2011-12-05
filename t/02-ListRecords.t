#!perl 
#-T doesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::OAI::Harvester::Plus;
use Debug::Simpler 'debug', 'debug_on';
use XML::LibXML;
debug_on();

{
	my $harvester = new HTTP::OAI::Harvester::Plus(
		baseURL => 'http://spk.mimo-project.eu:8080/oai',
		resume  => 0,
	);
	my $response =
	  $harvester->ListRecords( set => '78', metadataPrefix => 'oai_dc' );

	if ( $response && !$response->is_error ) {
		ok( ref $response eq 'HTTP::OAI::ListRecords',
			'ListRecords' . ref $response );
	} else {
		#dont need to continue testing
		die "something's wrong";
	}

	my $dom=$response->toDOM;
	ok (ref $dom eq 'XML::LibXML::Document', 'XML::LibXML::Document '. ref  $dom ); 

}

{
	my $harvester = new HTTP::OAI::Harvester::Plus(
		baseURL => 'http://spk.mimo-project.eu:8080/oai',
		resume  => 1
	);
	$harvester->register (limit=>1);
	my $response =
	  $harvester->ListRecords( set => '78', metadataPrefix => 'oai_dc' );

	if ( $response && !$response->is_error ) {
		ok( ref $response eq 'HTTP::OAI::ListRecords',
			'resume');
	}

	
}

