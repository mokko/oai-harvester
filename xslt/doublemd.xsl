<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />

	<!--
		There seems to be a bug in HTTP::OAI::Harvester which results in the metadata
		element to be repeated. This little transformation corrects this bug
	-->

	<xsl:template match="/">
		<xsl:copy>
			<xsl:apply-templates select="/oai:OAI-PMH" />
		</xsl:copy>
	</xsl:template>

	<!-- ListRecords-->
	<xsl:template
		match="/oai:OAI-PMH/oai:ListRecords/oai:record/oai:metadata">
		<xsl:apply-templates select="oai:metadata" />
	</xsl:template>

	<!-- GetRecord -->
	<xsl:template
		match="/oai:OAI-PMH/oai:GetRecord/oai:record/oai:metadata">
		<xsl:apply-templates select="oai:metadata" />
	</xsl:template>

	<!-- deep copy -->
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates />
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>