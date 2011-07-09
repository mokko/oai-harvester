#!/usr/bin/env perl
# ABSTRACT: Simple OAI harvester for the commandline

use strict;
use warnings;

use Cwd 'realpath';
use File::Spec;
use FindBin;
use Getopt::Std;
use HTTP::OAI;
use HTTP::OAI::Repository qw/validate_request/;
use HTTP::OAI::Headers;
use XML::LibXML;
use XML::LibXSLT;
use YAML::Syck qw/LoadFile/;    #use Dancer ':syntax';
use Pod::Usage;

getopts( 'o:huv', our $opts = {} );

pod2usage() if ( $opts->{h} );

sub verbose;

=head1 SYNOPSIS

harvest.pl [-v] conf.yml

Read the configuration specified in command line and harvest accordingly.

See 'perldoc harvest.pl' for full documentation.

=head1 CONFIGURATION FILE

Configuration file contains the oai verb and parameters in easy-to-understand
yaml format.  It can have the following parameters. Combine them with sense
according to OAI Specification Version 2 (see below).

	OAI STUFF

	baseURL (required):
		a base URL
	from:
		a oai datestamp
	metadataPrefix:
		prefix
	output:
		path, if specified output will be written to specified file
	set:
		a setSpec
	to:
		oai datestamp
	verb (required):
		OAI verb
	resume:
		true or false


	OTHER STUFF

	unwrap:
		true or false
	validate:
		true or false

Output file can be overwritten with -o option on commandline.

Unwrap returns the metadata contained in response (if any, only has an effect
with GetRecord and ListRecords).

=head2 Config example

	baseURL: 'http://spk.mimo-project.eu:8080/oai'
	verb: 'Identify'
	output: 'test.xml'

=head2 Command line arguments

	-h help (this text)
	-o output.xml
		write output to file; supersedes output in config file

=head2 Internal Functions

The following subs are just documented out of habit.

=cut

#command line
our $config = configSanity( $ARGV[0] );

#config file
my $params = paramsSanity($config);

#
# MAIN
#

my $verb = $params->{verb};
delete $params->{verb};

#args for harvester
my %args = ( 'baseURL' => $config->{baseURL}, );

$config->{resume} eq 'true'
  ? $args{resume} = 1
  : $args{resume} = 0;
my $harvester = HTTP::OAI::Harvester->new(%args);

#fix for HTTP::OAI::Harvester 3.25
#resume works only when onRecord is specified

#act on verb
my $response = $harvester->$verb( %{$params} );

if ( $response->is_error ) {
	print $response->code . " " . $response->message, "\n";
	exit 1;
}

#WORKAROUND TO MAKE RESUME WORK
if ( $response->resumptionToken && $config->{resume} eq 'true' ) {
	while ( my $rt = $response->resumptionToken ) {
		verbose 'auto resume ' . $rt->resumptionToken;
		$response->resume( resumptionToken => $rt );
		if ( $response->is_error ) {
			die( "Error resuming: " . $response->message . "\n" );
		}
	}
}

#
# OUTPUT
#

my $dom = unwrap($response);

output( $dom->toString );

#difficult not to let validator kill this script if it fails,
#so put him at the end
validate($dom);

#
# SUBS
#

sub configSanity {
	my $configFn = shift;

	if ( !$configFn ) {
		print "Error: Specify config file!\n";
		exit 1;
	}

	if ( !-f $configFn ) {
		print "Error: Specified file does not exist!\n";
		exit 1;
	}

	verbose "About to load config file ($configFn)";

	my $config = LoadFile($configFn) or die "Cannot load config file";

	#command line overwrites config file
	if ( $opts->{o} ) {
		$config->{output} = $opts->{o};
	}

	#ensure that there is the output key
	if ( $config->{output} ) {
		verbose "Output: " . $config->{output};
	} else {

		#init output even if empty to avoid uninitialized warning
		$config->{output} = '';
		verbose "Output: STDOUT";
	}

	#delete old file if any
	#if (-f $config->{output}) {
	#	verbose "delete old file";
	#	unlink $config->{output}
	#}

	if ( $config->{unwrap} ) {
		if ( $config->{unwrap} eq 'true' ) {
			$config->{unwrapFN} = realpath(
				File::Spec->catfile(
					$FindBin::Bin, '..', 'xslt', 'unwrap.xsl'
				)
			);
			if ( !-f $config->{unwrapFN} ) {
				print "Error: $config->{unwrapFN} not found";
				exit 1;
			}
			verbose "Unwrap (conf file): $config->{unwrap}";
		}

	} else {
		verbose "Unwrap (conf file): not defined -> false";
		$config->{unwrap} = 'false';
	}

	if ( !$config->{resume} ) {
		$config->{resume} = 'false';
	}
	verbose "Resume (conf file): $config->{resume}";

	if ( !$config->{validate} ) {
		$config->{validate} = 'false';
	}
	verbose "Validate (conf file): $config->{validate}";

	return $config;
}

=head2

Decides if it writes to STDOUT or to file. Is called from main or from unwrap
per file.

=cut

sub output {
	my $string      = shift;
	my $file        = shift;
	my $destination = $config->{output};
	if ($file) {

		#verbose "called with file: $file";
		$destination = File::Spec->catfile( $config->{output}, $file );
	}

	if ( !$string ) {
		die "Internal Error: Nothing to output!";
	}

	if ( $config->{output} ) {
		print 'Write ' . length($string) . " chars to file ($destination)\n";

		#' > : encoding( UTF- 8 ) ' seems to work without it
		open( my $fh, '> ', $destination )
		  or die 'Error: Cannot write to file:' . $destination . '! ' . $!;
		print $fh $string;
		close $fh;
	} else {
		verbose "Write STDOUT";
		print $string;
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

=head2 $dom=unwrap ($response);

Expects a HTTP::OAI response objects and returns a dom object.

=cut

sub unwrap {
	my $response = shift;
	my $dom      = $response->toDOM;
	if ( $config->{unwrapFN} ) {

		my $xslt      = XML::LibXSLT->new();
		my $style_doc = XML::LibXML->load_xml(
			location => $config->{unwrapFN},
			no_cdata => 1
		);
		my $stylesheet = $xslt->parse_stylesheet($style_doc);
		$dom = $stylesheet->transform($dom);
		verbose "unwrapping...";
	}

	return $dom;
}

sub validate {
	my $dom = shift;

	if ( $config->{validate} ne 'false' ) {
		verbose "Validating result against $config->{validate}";

		#don't let him die if validation fails!
		my $xmlschema =
		  XML::LibXML::Schema->new( location => $config->{validate} )
		  or die "Cannot init validation";

		eval { $xmlschema->validate($dom); };

		if ($@) {
			warn "validation failed: $@" if $@;
		} else {
			print "Validation succeeds\n";
		}
	}
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

=head1 KNOWN ISSUES

This harvester produces wrong xml. It doubles metadata element. Unwrap will
not work on all metadata formats, such as oai_dc.

=head1 SEE ALSO

=over

=item

OAI Specification at L<http://www.openarchives.org/OAI/openarchivesprotocol.html>

=item

HTTP::OAI::Repository

=item

HTTP::OAI::DataProvider (GitHub), Salsa_OAI (GitHub)

=back

=head1 COPYRIGHT / LICENSE

This little scrip is written by Maurice Mengel and should be available on
github.com/mokko/oai-harvester. It is based on Tim Brody's HTTP::OAI.
This script comes with absolutely no warranty and is under the same license
as Larry Wall's Perl 5.12.2. Written in 2011.

=cut
