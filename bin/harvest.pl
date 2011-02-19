#!/usr/bin/perl

use strict;
use warnings;
use HTTP::OAI;
use HTTP::OAI::Repository qw/validate_request/;
use HTTP::OAI::Headers;
use YAML::Syck qw/LoadFile/;    #use Dancer ':syntax';
use Getopt::Std;
use XML::LibXSLT;
use FindBin;
use Cwd 'realpath';
getopts( 'o:huv', my $opts = {} );

sub verbose;

=head1 NAME

Simple OAI harvester for the commandline

=head1 SYNOPSIS

harvest conf.yml

	Read the configuration in conf.yml and act accordingly.

=head1 CONFIGURATION FILE

Is in yaml format. Can have the following parameters. Use with sense according
to OAI Specification Version 2

	baseURL (required): URL
	from: oai datestamp
	metadataPrefix: prefix
	output: path, if specified output will be written to file
	set: setSpec
	to: oai datestamp
	verb (required): OAI verb
	unwrap: true

Output file can be overwritten with -o option on commandline.

Unwrap returns the metadata contained in response (if any, only has an effect
with GetRecord and ListRecords).

=head2 Config example

	baseURL: 'http://spk.mimo-project.eu:8080/oai'
	verb: 'Identify'
	output: 'test.xml'

=head2 Command line arguments

-h help (todo)
-o output.xml: write to file, supercedes output information in config file


=cut

#
# Command line and config sanity
#

our $config = configSanity( $ARGV[0] );
my $params = paramsSanity($config);
#path relative to bindir
$config->{unwrapXSL} = unwrapXSL('/../xslt/unwrap.xsl');

#
# MAIN
#

my $verb = $params->{verb};
delete $params->{verb};

my $harvester = HTTP::OAI::Harvester->new(
	'baseURL' => $config->{baseURL},
	'resume'  => 1
);

my $response = $harvester->$verb( %{$params} );

#
# OUTPUT
#

my $dom = unwrap($response);
output($dom);

#
# SUBS
#

sub configSanity {
	my $configFn = shift;

	if ( !$configFn ) {
		print "Error: Specify config file!";
		exit 1;
	}

	if ( !-f $configFn ) {
		print "Error: Specified file does not exist!";
		exit 1;
	}

	verbose "About to load config file ($configFn)";

	my $config = LoadFile($configFn) or die "Cannot load config file";

	#command line overwrites config file
	if ( $opts->{o} ) {
		$config->{output} = $opts->{o};
	}

	if (!$config->{unwrap}) {
		verbose "Set unwrap to false since not defined";
		$config->{unwrap}='false';
	}

	return $config;
}

sub output {
	my $dom = shift;

	if ( !$response ) {
		print "No response";
		exit 1;
	}

	if ( $config->{output} ) {
		verbose "Write to file ($config->{output})";

		#' > : encoding( UTF- 8 ) ' seems to work without it
		open( my $fh, ' >> ', $config->{output} ) or die $!;
		print $fh $dom->toString;
		close $fh;
	} else {
		verbose "Write STDOUT";
		print $dom->toString;
	}
}

sub paramsSanity {
	my $conf = shift;

	my $params = {};
	my @import = qw/identifier metadataPrefix verb from to set/;

	verbose "Params from config file:";
	foreach (@import) {
		if ( $conf->{$_} ) {
			$params->{$_} = $conf->{$_};

			#delete $conf->{$_};
			verbose "  $_:" . $params->{$_};
		}
	}

	if ( validate_request( %{$params} ) ) {
		my @errs = validate_request( %{$params} );

		foreach (@errs) {
			print $_->code . "\n";
		}
		exit 1;
	}
	verbose "Request validates";
	return $params;
}

=head2 verbose "message";

Print message to STDOUT if script is run with -v options.

=cut

sub verbose {
	my $msg = shift;
	if ($msg) {
		if ( $opts->{v} ) {
			print $msg. "\n";
		}
	}
}

=head2 my $dom=unwrap ($response);

Expects a HTTP::OAI::Response object and returns a dom. If the conditions are
right it returns a transformation. It might also just write transformation to
file and be done with it.

=cut

sub unwrap {
	my $response = shift;
	if ( $config->{unwrap} eq 'true' ) {
		if (   $config->{verb} eq 'GetRecord'
			or $config->{verb} eq 'ListRecords' )
		{
			return _unwrap( $response->toDOM );
		}
	}
	return $response->toDOM;
}

sub _unwrap {
	my $source    = shift; #supposed to be dom
	my $xslt      = XML::LibXSLT->new();
	my $style_doc = XML::LibXML->load_xml(
		location => $config->{unwrapXSL},
		no_cdata => 1
	);
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	my $result     = $stylesheet->transform($source);
	if ( $config->{output} ) {
		verbose "Writing unwrapped version to file ($config->{output})";
		$stylesheet->output_file($result, $config->{output});
		exit;
	}
	return $result; #supposed to be a XML::LibXML::Document
}

=head2 my $fullpath=unwrapXSL ($path);

Expects a relative path, relative to bindir

=cut

sub unwrapXSL {
	my $path = shift;
	return realpath( $FindBin::Bin . $path );
}

