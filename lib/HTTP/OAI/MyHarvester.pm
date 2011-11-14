package HTTP::OAI::MyHarvester;

# ABSTRACT: Remidy for issues I have with HTTP::OAI::Harvester

use strict;
use warnings;
use HTTP::OAI;
use parent 'HTTP::OAI::Harvester';
use Debug::Simpler 'debug', 'debug_on';
use Carp 'carp',            'croak';
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


=cut

sub ListRecords {
	my $self   = shift or die "somethings really wrong";
	my %params = @_    or die "somethings really wrong";

	my $response = $self->HTTP::OAI::Harvester::ListRecords(%params);

	if ( $response->is_error ) {
		print $response->code . ' ' . $response->message, "\n";
		exit 1;
	}

	if ( $response->resumptionToken && $self->{resume} eq 1 ) {
		while ( my $rt = $response->resumptionToken ) {
			debug 'auto resume ' . $rt->resumptionToken;
			$response->resume( resumptionToken => $rt );
			if ( $response->is_error ) {
				die( "Error resuming: " . $response->message . "\n" );
			}
		}
	}
	return $response;
}

sub ListIdentifiers {
	debug 'dddddddd' . $0;
}

sub unwrap {
	my $self     = shift;
	my $response = shift;

	if ( ref $response !~ /^HTTP::OAI::/ ) {
		carp "Response is not the right object:" . ref $response;
	}

	my $modDir = dirname abs_path __FILE__;
	my $xsl_fn =
	  File::Spec->catfile( $modDir, '..', '..', '..', 'xslt', 'unwrap.xsl' );

	debug "unwrapping... $xsl_fn|" . ref $response;
	my $xslt      = XML::LibXSLT->new();
	my $style_doc = XML::LibXML->load_xml(
		location => $xsl_fn,
		no_cdata => 1
	);
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	return $stylesheet->transform($response);
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

42;
