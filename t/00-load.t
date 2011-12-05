#!perl 
#-T doesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok( 'HTTP::OAI::Harvester::Plus' ) || print "Bail out!";
}

diag( "Testing HTTP::OAI::Harvester:Plus $HTTP::OAI::Harvester::Plus::VERSION, Perl $], $^X" );