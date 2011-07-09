#!/usr/bin/env perl

use strict;
use warnings;
use HTTP::OAI;

#http://spk.mimo-project.eu:8080/oai
my $harvester = HTTP::OAI::Harvester->new(
	'baseURL' => 'http://localhost:3000/oai',
	resume    => 1,
);

print 'RESUME?' . $harvester->resume . "\n";

my $cb = sub {
	my $rec = shift;

	#	$response->record($rec);
	print "Identifier => ", $rec->identifier, "\n";
};

my $response = $harvester->ListRecords(
	metadataPrefix => 'oai_dc',
	set            => '78',

	#onRecord => sub {1;},
);

if ( $response->is_error ) {
	die( "Error harvesting: " . $response->message . "\n" );
}

die "resume not true" unless $harvester->resume == 1;
die "no rt" unless $response->resumptionToken;

while ( my $rt = $response->resumptionToken) {
	print 'get here ' . $rt->resumptionToken . "\n";
	$response->resume( resumptionToken => $rt );
	if ( $response->is_error ) {
		die( "Error resuming: " . $response->message . "\n" );
	}
}


my $str = $response->toDOM->toString;

print "length:" . length $str;
print "$str\n";
