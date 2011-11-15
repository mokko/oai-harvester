#!perl 
#-T doesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::OAI::MyHarvester;

my $harvester = new HTTP::OAI::MyHarvester( baseURL => 'test' );
ok( ref $harvester eq 'HTTP::OAI::MyHarvester',
	'new succeeds' . ref $harvester );

my $response = $harvester->Identify();
ok( ref $response eq 'HTTP::OAI::Identify', 'new succeeds' );


