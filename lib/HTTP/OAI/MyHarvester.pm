package HTTP::OAI::MyHarvester;

# ABSTRACT: Remedy for my issues with HTTP::OAI::Harvester

use strict;
use warnings;
use HTTP::OAI;
use parent 'HTTP::OAI::Harvester';
use Debug::Simpler 'debug', 'debug_on';
use Carp 'carp',            'croak';
use XML::LibXML;
use XML::LibXSLT;
use File::Basename qw(dirname);
use File::Spec;
use Cwd qw(abs_path);

debug_on();

=head2 SYNOPSIS

	my $harvester= HTTP::OAI::Harvester->new(%options);
 	$response=$harvester->ListRecords (%params);
	...

	the original interface is imported from HTTP::OAI::Harvester

	my $dom=$harvester->unwrap($response);


=head1 DESCRIPTION

For unknown reasons, HTTP::OAI::Harvester's resume function doesn't work for 
me. This little module acts as a fix for this problem. It also provides a
method for unwrapping the xml contained in the OAI protocoll. Here again,
HTTP::OAI::Harvester gives me a problem. The metadata element appears twice.
My unwrap method silently corrects this error.

PS: I am not 100% that the errors described above come from 
HTTP::OAI::Harverster. It is conceivable that they caused by the 
implementation.

=cut

sub ListRecords {
	my $self   = shift or die "somethings really wrong";
	my %params = @_    or die "somethings really wrong";

	my $response = $self->HTTP::OAI::Harvester::ListRecords(%params);

	return $self->_resume($response);
}

sub ListIdentifiers {
	my $self   = shift or die "somethings really wrong";
	my %params = @_    or die "somethings really wrong";

	my $response = $self->HTTP::OAI::Harvester::ListIdentifiers(%params);

	return $self->_resume($response);
}

sub _resume {
	my $self     = shift or die "somethings really wrong";
	my $response = shift or die "somethings really wrong";

	if ( $response->is_error ) {
		print $response->code . ' ' . $response->message, "\n";
		exit 1;
	}

	if ( $response->resumptionToken && $self->{resume} eq 1 ) {
		while ( my $rt = $response->resumptionToken ) {

			#debug 'auto resume ' . $rt->resumptionToken;
			$response->resume( resumptionToken => $rt );
			if ( $response->is_error ) {
				die( "Error resuming: " . $response->message . "\n" );
			}
		}
	}
	return $response;
}

sub unwrap {
	my $self     = shift or die "Something's wrong!";
	my $response = shift or return 0;

	if ( ref $response !~ /^HTTP::OAI::/ ) {
		carp "Response is not the right object:" . ref $response;
	}
	my $this     = abs_path __FILE__;
	$this =~ s/\.pm$//;
	my $xsl_fn = File::Spec->catfile( $this, 'unwrap.xsl' );

	#debug "unwrapping... $xsl_fn";
	#if (-f $xsl_fn) {
	#	debug "xsl_fn exists";
	#}
	my $style_doc = XML::LibXML->load_xml(
		location => $xsl_fn,
		no_cdata => 1
	);
	my $xslt=XML::LibXSLT->new();
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	return $stylesheet->transform($response->toDOM);
}

=head2 todo

sub validate {
	my $dom = shift;

	#if ( $config->{validate} ne 'false' ) {
		debug "Validating result against $config->{validate}";

		#don't let him die if validation fails!
		#my $xmlschema =
		#  XML::LibXML::Schema->new( location => $config->{validate} )
		#  or die "Cannot init validation";

		#eval { $xmlschema->validate($dom); };

		if ($@) {
			warn "validation failed: $@" if $@;
		} else {
			print "Validation succeeds\n";
		}
	#}
}

=cut

1;
