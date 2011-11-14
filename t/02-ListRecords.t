#!perl 
#-T doesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::OAI::MyHarvester;
use Debug::Simpler 'debug', 'debug_on';
use XML::LibXML;
debug_on();

{
	my $harvester = new HTTP::OAI::MyHarvester(
		baseURL => 'http://spk.mimo-project.eu:8080/oai',
		resume  => 0,
		unwrap => '/home/maurice/projects/Harvester/xslt/unwrap.xsl',
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
	ok (ref $dom eq 'XML::LibXML::Document', 'XML::LibXML::Document'); 
	my $newdom=$harvester->unwrap ($response);
	ok (ref $newdom eq 'XML::LibXML::Document', 'XML::LibXML::Document'); 
	
	#debug $newdom->toString;
	$harvester->ListIdentifiers;
	exit;
}

{
	my $harvester = new HTTP::OAI::MyHarvester(
		baseURL => 'http://spk.mimo-project.eu:8080/oai',
		resume  => 1
	);
	my $response =
	  $harvester->ListRecords( set => '78', metadataPrefix => 'oai_dc' );

	if ( $response && !$response->is_error ) {
		ok( ref $response eq 'HTTP::OAI::ListRecords',
			'ListRecords' . ref $response );
	}

	
}

