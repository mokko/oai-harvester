#!/usr/bin/perl

use strict;
use warnings;
use HTTP::OAI;
use HTTP::OAI::Repository qw/validate_request/;
use HTTP::OAI::Headers;
use YAML::Syck qw/LoadFile/;    #use Dancer ':syntax';
use Getopt::Std;
use FindBin;
use Cwd 'realpath';
getopts( 'o:huv', my $opts = {} );

use XML::SAX::Writer;

sub verbose;

=head1 NAME

Simple OAI harvester for the commandline

=head1 SYNOPSIS

harvest conf.yml

	Read the configuration in conf.yml and act accordingly.

=head1 CONFIGURATION FILE

Is in yaml format. Can have the following parameters. Use with sense according
to OAI Specification Version 2

	baseURL (required): 'URL'
	from: a oai datestamp
	metadataPrefix: prefix
	output: path, if specified output will be written to file
	set: setSpec
	to: oai datestamp
	verb (required): OAI verb
	unwrap: true or false
	resume: true or false


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

#path relative to bindir/ change path if necessary

#testing if this solves metadata/metadata problem

#
# MAIN
#

my $verb = $params->{verb};
delete $params->{verb};

my $harvester;
{
	my %args = ( 'baseURL' => $config->{baseURL}, );

	$config->{resume} eq 'true'
	  ? $args{resume} = 1
	  : $args{resume} = 0;
	$harvester = HTTP::OAI::Harvester->new(%args);
}

my $response = $harvester->$verb( %{$params} );

#
# OUTPUT
#

if ( !$config->{already} ) {
	output( $response->toDOM->toString );
}

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

	#ensure that there is the output key
	if ( $config->{output} ) {
		verbose "Output: ".$config->{output};
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
		verbose "Unwrap (conf file): $config->{unwrap}";
		if ( $config->{unwrap} eq 'true' ) {
			die "Error: Unwrap does not YET work as expected";
			if ( !-d $config->{output} ) {
				print "Error: Output has to be dir to unwrap into it";
				exit 1;
			}
		}

	} else {
		verbose "Unwrap (conf file): not defined -> false";
		$config->{unwrap} = 'false';
	}

	if ( !$config->{resume} ) {
		$config->{resume} = 'false';
	}
	verbose "Resume (conf file): $config->{resume}";

	return $config;
}

=head2

Decides it it writes to STDOUT or to file. Is called from main or from unwrap
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
		verbose "Write to file ($destination)";
		#' > : encoding( UTF- 8 ) ' seems to work without it
		open( my $fh, '> ', $destination )
		  or die 'Error: Cannot write to file:' . $destination . $!;
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

	#I had guessed that this callback would be called on
	my $unwrapCB = sub {
		my $record = shift;
		if ($record) {
			if ( !$record->status ) {    #not deleted
				my $fn = $record->identifier;

				#mk filename
				$fn =~ s/\s/_/;          #whitespace in fn not good
				$fn =~ s/:/-/;           #colon in filename not good
				$fn .= '.xml';

				if ( $record->metadata ) {

					#don't write output again since already written
					$config->{already} = 'true';

					#verbose "About to write ($fn)";
					output( $record->metadata->toString, $fn );
				}
			}
		}
	};

	if ( $config->{unwrap} eq 'true' ) {
		$params->{onRecord} = $unwrapCB;

		#$params->{handlers}->{metadata} = undef;
	}

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
