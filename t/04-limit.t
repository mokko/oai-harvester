#!perl
use strict;
use warnings;
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/../lib";


#I need a local data provider for testing purposes
#use HTTP::OAI::DataProvider;