#!perl 
#-T doesn't work with FindBin

use strict;
use warnings;
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok( 'HTTP::OAI::MyHarvester' ) || print "Bail out!";
}

diag( "Testing HTTP::OAI::MyHarvester $HTTP::OAI::MyHarvester::VERSION, Perl $], $^X" );