package HTTP::OAI::Harvester::Plus;

# ABSTRACT: Remedy for my issues with HTTP::OAI::Harvester

use strict;
use warnings;
use HTTP::OAI;
use parent 'HTTP::OAI::Harvester';
use Debug::Simpler 'debug', 'debug_on';
use Carp 'carp';
use XML::LibXML;
use XML::LibXSLT;
use File::Basename qw(dirname);
use File::Spec;
use Cwd qw(abs_path);

our %options;    #for progress and limit

debug_on();

=head2 SYNOPSIS

	my $harvester= HTTP::OAI::Harvester->new(%options);
 	$response=$harvester->ListRecords (%params);
	...

	#the original interface is imported from HTTP::OAI::Harvester
	#additionally

	my $dom=$harvester->unwrap($response);

	#new option for new: progress=>sub{print '.'}

=head1 DESCRIPTION

For unknown reasons, HTTP::OAI::Harvester's resume function doesn't work for 
me. This little module acts as a fix for this problem. It also provides a
method for unwrapping the xml contained in the OAI protocol. Here again,
HTTP::OAI::Harvester gives me a problem. The metadata element appears twice.
My unwrap method silently corrects this error.

PS: I am not 100% that the errors described above come from 
HTTP::OAI::Harverster. It is conceivable that they caused by the 
implementation.

=cut

sub ListRecords {
	my $self   = shift or die "somethings really wrong";
	my %params = @_    or die "somethings really wrong";

	_showProgress();
	my $response = $self->HTTP::OAI::Harvester::ListRecords(%params);

	return $self->_resume($response);
}

sub ListIdentifiers {
	my $self   = shift or die "somethings really wrong";
	my %params = @_    or die "somethings really wrong";

	_showProgress();
	my $response = $self->HTTP::OAI::Harvester::ListIdentifiers(%params);

	return $self->_resume($response);
}

=method $harvester->register(%options);

Register an option with the harvester object: 

$options{progress}=&callback(); 

Is called on every resume to output a progress status

=cut

sub register {
	my $self = shift;
	my %opts = @_;

	if ( $opts{progress} ) {
		debug "Register progress";
		if ( ref $opts{progress} ne 'CODE' ) {
			carp "Cannot register progress";
		}
		$options{progress} = $opts{progress};
	}

	if ( $opts{limit} ) {
		if ( $opts{limit} !~ /\d+/ ) {
			carp "Cannot register limit " . $opts{limit};
		}
		debug "Register limit " . $opts{limit};
		$options{limit} = $opts{limit};
	}
}

#depends on resume and stops on limit
sub _resume {
	my $self     = shift or die "somethings really wrong";
	my $response = shift or die "somethings really wrong";

	if ( $response->is_error ) {
		print $response->code . ' ' . $response->message, "\n";
		exit 1;
	}

	if ( $response->resumptionToken && $self->{resume} eq 1 ) {
		my $count = 1;
		if ( $options{limit} && $options{limit} =~ /\d+/ ) {
			$options{_limit} = $options{limit};
		}
		else {
			$options{_limit} = 10;
		}

		while (
			my $rt = $response->resumptionToken
			and ( $count < $options{_limit} )
		  )
		{
			$count++;
			$options{_limit}++ if ( !$options{limit} );
			_showProgress();

			#debug "limit VS count: $options{limit} < $count ";

			$response->resume( resumptionToken => $rt );
			if ( $response->is_error ) {
				die( "Error resuming: " . $response->message . "\n" );
			}
		}
	}
	return $response;
}

sub _showProgress {
	if ( $options{progress} ) {
		$options{progress}();
	}
}

sub _getDom {
	my $input = shift or return;

	if (   ref $input eq 'HTTP::OAI::ListRecords'
		or ref $input eq 'HTTP::OAI::ListIdentifiers'
		or ref $input eq 'HTTP::OAI::GetRecord' )
	{
		return $input->toDOM;
	}
	else {
		return $input;
	}
}

sub _findFile {
	my $this = abs_path __FILE__;
	$this =~ s/\.pm$//;
	return File::Spec->catfile( $this, 'unwrap.xsl' );

	#debug "unwrapping... $xsl_fn";
	#if (-f $xsl_fn) {
	#	debug "xsl_fn exists";
	#}
}

=head2 my $dom_unwrapped=$harvester->unwrap ($dom_wrapped);

Expects a XML::LibXML::Document, HTTP::OAI::ListRecords or 
HTTP::OAI::ListIdentifiers object. Returns the unwrapped version as a 
XML::LibXML::Document or empty on failure. 

Unwrapping is a mechanism of extracting the metadata from the OAI response that
does not work with all metadata formats. It fails with oai_dc for example.

=cut

sub unwrap {
	my $self = shift          or die "Something's wrong!";
	#my $dom  = _getDom(shift) or return;
	my $string  = shift;
	my $dom = XML::LibXML->load_xml(string => $string);
	#my $output_fn=shift or return;

	#if ( ref $dom !~ /^XML::LibXML::Document/ ) {
	#	carp "Input is not the right object:" . ref $dom;
	#}
	my $xsl_fn = _findFile() or carp "unwrap.xsl not found!";

	my $style_doc = XML::LibXML->load_xml(
		location => $xsl_fn,
		no_cdata => 1
	);
	my $xslt       = XML::LibXSLT->new();
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	#print "DOM:$dom\n";
	my $results=$stylesheet->transform($dom);
	#return $stylesheet->output_as_chars($results);
	#
	return $results;
	#$result=$stylesheet->output_string($result);
}

=cut

1;
