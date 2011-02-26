#!/usr/bin/perl

use strict;
use warnings;
use XML::LibXSLT;
use XML::LibXML;

#test pp with XML::LibXSLT

my $source = XML::LibXML->load_xml(string => <<'EOT');
<xml><test/></xml>
EOT

my $style_doc = XML::LibXML->load_xml(string => <<'EOT', no_cdata=>1);
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
version="1.0"><xsl:template match="/"><anothertest/></xsl:template></xsl:stylesheet>
EOT

my $xslt       = XML::LibXSLT->new();
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $result = $stylesheet->transform($source);
#only saves if there is a result document
$stylesheet->output_file($result, 'test.xml');
