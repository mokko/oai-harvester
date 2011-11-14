#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::XPath;

#I assume that before this test is run schema validation passes!

#
# PRELIMINARIES
#

my $path = '/home/Mengel/projects/Harvester/xml-unwrapped/';
my $file = $path . 'GetRecord61117.lido.xml';

#ok($got eq $expected, $test_name);
ok( ( -f $file eq 1 ), 'file exists' );
diag "file exists: $file";

my $tx = Test::XPath->new(
	file  => $file,
	xmlns => { lido => 'http://www.lido-schema.org' }
);

ok( ref $tx eq 'Test::XPath', 'tx made successfully' );

#
# MEAT
#

#no trailing slash!
#$tx->ok( '/html/head', 'There should be a head' );
$tx->ok(
	'/lido:lidoWrap/lido:lido/lido:descriptiveMetadata'
	  . '/lido:objectIdentificationWrap/lido:titleWrap/'
	  . 'lido:titleSet/lido:appellationValue',
	'title exists'
);

#$tx->is( '/html/head/title', 'Hello', 'The title should be correct' );
$tx->is(
	'/lido:lidoWrap/lido:lido/lido:descriptiveMetadata'
	  . '/lido:objectIdentificationWrap/lido:titleWrap/'
	  . 'lido:titleSet/lido:appellationValue',
	'[ Vorgang 1 B/1984:1 ]',
	'title is correct'
);

