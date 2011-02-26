#!/usr/bin/perl

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
use YAML::Syck qw/LoadFile/;    #use Dancer ':syntax';

getopts( 'o:huv', our $opts = {} );

help() if ( $opts->{h} );

sub verbose;

=head1 NAME

harvest - Simple OAI harvester for the commandline

=head1 SYNOPSIS

harvest [-v] conf.yml

Read the configuration in conf.yml and act accordingly.

=head1 VERSION

0.01 - crippled version without xslt

=head1 CONFIGURATION FILE

Configuration file contains the oai verb and parameters in easy-to-understand
yaml format.  It can have the following parameters. Combine them with sense
according to OAI Specification Version 2 (see below).

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
	#unwrap: doesn't work in the crippled version
	#	true or false
	resume:
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
output( $response->toDOM->toString );

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



=head2 help

=cut

sub help {
	system "perldoc $0";
	exit;
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
