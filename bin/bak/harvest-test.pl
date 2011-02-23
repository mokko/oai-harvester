#!/usr/bin/perl

use strict;
use warnings;
use HTTP::OAI;

#write the something close to the shortest possible test to see where the
#problem lies

my $harvester = HTTP::OAI::Harvester->new(
	baseURL => 'http://localhost:3000/oai',
	resume  => 0
);

my $response = $harvester->ListRecords( metadataPrefix => 'oai_dc' );

print $response->toDOM->toString;