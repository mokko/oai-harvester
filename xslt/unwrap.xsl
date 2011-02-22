<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />

	<!-- metadata is double in my harvester. This is the quickest and dirtiest fix -->

	<!--
		oai_dc cannot correcntly and easily be unwrapped into a single document. The
		format can only describe one resource per xml document (file).

		Unwrapping originally intended to write a ListRecord into one file. I could
		however write to multiple files, however this is not possible in xslt1

		In XSLT2, I could write each record to a separate file named according to
		identifier. A further disadvantage is that unwrapping is not format agnostic
		anymore. Unless we always employ the multiple result documents strategy.

		If we do, then I could just as well avoid xslt altogether in the unwrapper and
		simply use HTTP::OAI accessor to the metadata, probably with the callback
		onRecord.

		Some formats could still be unwrapped into a single file, e.g. mpx or lido.
	-->

	<xsl:template match="/">
		<xsl:copy>
			<xsl:apply-templates
				select="/oai:OAI-PMH/oai:ListRecords/oai:record/oai:metadata/oai:metadata/*" />
			<xsl:apply-templates
				select="/oai:OAI-PMH/oai:GetRecord/oai:record/oai:metadata/oai:metadata/*" />
		</xsl:copy>
	</xsl:template>

	<xsl:template
		match="/oai:OAI-PMH/oai:ListRecords/oai:record/oai:metadata/oai:metadata/*">
		<xsl:if test="position()=1">
			<xsl:copy>
				<xsl:apply-templates
					select="/oai:OAI-PMH/oai:ListRecords/oai:record/oai:metadata/oai:metadata/*/*">
					<xsl:sort select="name()" />
				</xsl:apply-templates>
			</xsl:copy>
		</xsl:if>
	</xsl:template>

	<xsl:template
		match="/oai:OAI-PMH/oai:GetRecord/oai:record/oai:metadata/oai:metadata/*">
		<xsl:if test="position()=1">
			<xsl:copy>
				<xsl:apply-templates
					select="/oai:OAI-PMH/oai:GetRecord/oai:record/oai:metadata/oai:metadata/*/*">
					<xsl:sort select="name()" />
				</xsl:apply-templates>
			</xsl:copy>
		</xsl:if>
	</xsl:template>


	<xsl:template
		match="/oai:OAI-PMH/oai:ListRecords/oai:record/oai:metadata/oai:metadata/*/*">
		<xsl:copy-of select="." />
	</xsl:template>

	<xsl:template
		match="/oai:OAI-PMH/oai:GetRecord/oai:record/oai:metadata/oai:metadata/*/*">
		<xsl:copy-of select="." />
	</xsl:template>

</xsl:stylesheet>