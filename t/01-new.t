#!perl
#-Tdoesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::OAI::Harvester::Plus;

my $harvester = new HTTP::OAI::Harvester::Plus( baseURL => 'test' );
ok( ref $harvester eq 'HTTP::OAI::Harvester::Plus',
	' new succeeds' . ref $harvester );

my $response = $harvester->Identify();
ok( ref $response eq 'HTTP::OAI::Identify', ' Identify succeeds' );


