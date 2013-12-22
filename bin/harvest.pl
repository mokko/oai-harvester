#!perl
# ABSTRACT: Simple OAI harvester for the commandline
# PODNAME: harvest.pl

use strict;
use warnings;

use Cwd 'realpath';
use File::Spec;
use Getopt::Std;
use XML::SAX::Writer;
use Encode qw/encode_utf8/; #encoding problem when dealing with data from sqlite

#use FindBin;
#use lib "$FindBin::Bin/../lib";

use HTTP::OAI::Harvester::Plus;
use HTTP::OAI::Repository qw/validate_request/;

#use HTTP::OAI::Headers;
use YAML::Syck qw/LoadFile/;    #use Dancer ':syntax';
use Pod::Usage;
use Debug::Simpler 'debug';

#Debug::Simpler::debug_off();
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

	OTHER STUFF
	resume:
		true or false
	resumptionToken:
		resumptionToken as string 
	limit: 5
	    number of times ListRecord and ListIdentifiers should resume.
	    A limit of 0 resumes until done.
	unwrap:
		true or false
	validate:
		true or false
	chunk: true|false. Instead of writing output to one big file harverster 
		splits output in several files, where every part consists of the number
		of pages specified in limit, or if limit unspecified a default
		value. (TODO) 

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

#command line & config file
my $config = configSanity( $ARGV[0] );
my ( $verb, $params ) = paramsSanity($config);

#
# MAIN
#

#args for harvester
my %args = ( 'baseURL' => $config->{baseURL}, );

if ( $config->{resume} eq 'true' ) {
	$args{resume} = 1;
}
else {
	$args{resume} = 0;
}

#debug "args resume" . $args{resume} . $config->{resume};
my $harvester = new HTTP::OAI::Harvester::Plus(%args) or die "No harvester";
$harvester->register( progress => sub { $|++; print '.'; } );

if ( $config->{limit} && $config->{limit} =~ /\d+/ ) {
	$harvester->register( limit => $config->{limit} );
}

#act on verb
my $response = $harvester->$verb( %{$params} );

#}

if ( $response->is_error ) {
	print $response->code . " " . $response->message, "\n";
	exit 1;
}

#
# OUTPUT
#
my $xml;
$response->set_handler( XML::SAX::Writer->new( Output => \$xml ) );
$response->generate;
encode_utf8($xml);

if ( $config->{unwrap} eq 'true' ) {
	debug "Unwrapping";
	$xml = $harvester->unwrap($xml, $config->{output});
	#exit 0;
}


output($xml);

#else {
#$dom = $response->toDOM;
#}

#if ($dom) {
#	output( $dom->toString(1) );
#}
#else {
#
#could be because nothing is return, right?
#	debug "no return value!";
#}

#difficult not to let validator kill this script if it fails,
#so put him at the end
#$harvester->validate($dom);

#
# SUBS
#

#process both command-line input and conf file
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

	debug "Load config file ($configFn)";

	if ( $opts->{v} ) {
		Debug::Simpler::debug_on();
		debug "Verbose mode on";
	}
	else {
		Debug::Simpler::debug_off();
	}

	my $config = LoadFile($configFn) or die "Cannot load config file";

	#command line overwrites config file
	if ( $opts->{o} ) {
		$config->{output} = $opts->{o};
	}

	#ensure that there is the output key
	if ( $config->{output} ) {
		debug "Output: " . $config->{output};
	}
	else {

		#init output even if empty to avoid uninitialized warning
		$config->{output} = '';
		debug "Output: STDOUT";
	}

	if ( $config->{unwrap} ) {
		if ( $config->{unwrap} eq 'true' ) {
			debug "Unwrap: $config->{unwrap}";
		}

	}
	else {
		debug "Unwrap: not defined -> false";
		$config->{unwrap} = 'false';
	}

	if ( !$config->{resume} ) {
		$config->{resume} = 'false';
	}
	debug "Resume: $config->{resume}";

	if ( !$config->{validate} ) {
		$config->{validate} = 'false';
	}
	else {
		debug "Validate: $config->{validate}";
	}

	if ( $config->{limit} ) {
		debug "resume limit set: " . $config->{limit};
	}

	if ( $config->{chunk} && $config->{chunk} eq 'true' ) {
		debug "chunking on. Split output in several files";
		if ( !$config->{limit} ) {
			debug "Use default limit: $config->{limit} resumes";
			$config->{limit} = 25;
		}
	}
	else {
		$config->{chunk} = '';
	}

	if ( $config->{resumptionToken} ) {
		debug "resumptionToken: " . $config->{resumptionToken};
	}

	return $config;
}

=head2

Decides if it writes to STDOUT or to file. Is called from main or from unwrap
per file.

=cut

sub output {
	my $string = shift;

	if ( !$string ) {
		die "Internal Error: Nothing to output!";
	}

	if ( $config->{output} ) {
		print "\nWrite "
		  . length($string)
		  . " chars to file '$config->{output}'\n";

		# ' > : encoding(UTF-8) ' seems to work without it
		open( my $fh, '> : encoding(UTF-8)', $config->{output} )
		  or die 'Error: Cannot write to file:'
		  . $config->{output} . '! '
		  . $!;
		print $fh $string;
		close $fh;
	}
	else {
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

	my $verb = $params->{verb};
	delete $params->{verb};

	return $verb, $params;
}

=head1 KNOWN ISSUES

This harvester produces wrong xml. It doubles metadata element. Unwrap will
not work on all metadata formats, such as oai_dc.

=head1 SEE ALSO

=over 3

=item

OAI Specification L<http://www.openarchives.org/OAI/openarchivesprotocol.html>

=item

HTTP::OAI::Repository

=item

HTTP::OAI::DataProvider (GitHub), Salsa_OAI (GitHub)


=cut
