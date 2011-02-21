#!/usr/bin/perl

use strict;
use warnings;
use Net::OAI::Harvester;

#write the something close to the shortest possible test to see where the
#problem lies

my $harvester = Net::OAI::Harvester->new(
	baseURL => 'http://localhost:3000/oai',
);

my $records = $harvester->listRecords( metadataPrefix => 'oai_dc' );

while (my $record = $records->next()) {
	my $metadata= $record->metadata();
	print $metadata;
}

