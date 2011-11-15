#!/usr/bin/env perl
# ABSTRACT: Simple OAI harvester for the commandline
# PODNAME: harvest.pl

use strict;
use warnings;

use Cwd 'realpath';
use File::Spec;
use Getopt::Std;

use FindBin;
use lib "$FindBin::Bin/../lib";

use HTTP::OAI::MyHarvester;
use HTTP::OAI::Repository qw/validate_request/;
#use HTTP::OAI::Headers;
use YAML::Syck qw/LoadFile/;    #use Dancer ':syntax';
use Pod::Usage;
use Debug::Simpler 'debug','debug_on';
debug_on(); 
getopts( 'o:huv', our $opts = {} );
pod2usage() if ( $opts->{h} );


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
my $harvester = new HTTP::OAI::MyHarvester (%args);

#fix for HTTP::OAI::Harvester 3.25
#resume works only when onRecord is specified

#act on verb
my $response = $harvester->$verb( %{$params} );

if ( $response->is_error ) {
	print $response->code . " " . $response->message, "\n";
	exit 1;
}

#WORKAROUND TO MAKE RESUME WORK
#resume only if ListIdentifiers and ListRecords
if ( $verb =~ /ListRecords|ListIdentifiers/ ) {
	if ( $response->resumptionToken && $config->{resume} eq 'true' ) {
		while ( my $rt = $response->resumptionToken ) {
			debug 'auto resume ' . $rt->resumptionToken;
			$response->resume( resumptionToken => $rt );
			if ( $response->is_error ) {
				die( "Error resuming: " . $response->message . "\n" );
			}
		}
	}
}

#
# OUTPUT
#
my $dom = $harvester->unwrap( $response->toDOM );

output( $dom->toString(1) );

#difficult not to let validator kill this script if it fails,
#so put him at the end
#$harvester->validate($dom);

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

	debug "About to load config file ($configFn)";

	my $config = LoadFile($configFn) or die "Cannot load config file";

	#command line overwrites config file
	if ( $opts->{o} ) {
		$config->{output} = $opts->{o};
	}

	#ensure that there is the output key
	if ( $config->{output} ) {
		debug "Output: " . $config->{output};
	} else {

		#init output even if empty to avoid uninitialized warning
		$config->{output} = '';
		debug "Output: STDOUT";
	}

	#delete old file if any
	#if (-f $config->{output}) {
	#	debug "delete old file";
	#	unlink $config->{output}
	#}

	if ( $config->{unwrap} ) {
		if ( $config->{unwrap} eq 'true' ) {
			debug "Unwrap (conf file): $config->{unwrap}";
		}

	} else {
		debug "Unwrap (conf file): not defined -> false";
		$config->{unwrap} = 'false';
	}

	if ( !$config->{resume} ) {
		$config->{resume} = 'false';
	}
	debug "Resume (conf file): $config->{resume}";

	if ( !$config->{validate} ) {
		$config->{validate} = 'false';
	}
	debug "Validate (conf file): $config->{validate}";

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

		#debug "called with file: $file";
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
		debug "Write STDOUT";
		print $string;
	}
}

sub paramsSanity {
	my $conf = shift;

	my $params = {};
	my @import = qw/identifier metadataPrefix verb from to set/;

	debug "Params from config file:";
	foreach (@import) {
		if ( $conf->{$_} ) {
			$params->{$_} = $conf->{$_};

			#delete $conf->{$_};
			debug "  $_:" . $params->{$_};
		}
	}

	if ( validate_request( %{$params} ) ) {
		my @errs = validate_request( %{$params} );

		foreach (@errs) {
			print $_->code . "\n";
		}
		exit 1;
	}
	debug "Request validates";
	return $params;
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


=cut
