#!perl 
#-T doesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::OAI::MyHarvester;

my $harvester = new HTTP::OAI::MyHarvester( baseURL => 'test' );
ok( ref $harvester eq 'HTTP::OAI::MyHarvester',
	'new succeeds' . ref $harvester );

my $response = $harvester->Identify();
ok( ref $response eq 'HTTP::OAI::Identify', 'new succeeds' );

$harvester = new HTTP::OAI::MyHarvester(
	baseURL => 'test',
	unwrap  => '/home/maurice/projects/Harvester/xslt/unwrap.xsl'
);
ok( ref $harvester eq 'HTTP::OAI::MyHarvester',
	'new with unwrap' . ref $harvester );

