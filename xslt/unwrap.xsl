<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*"/>

	<!-- metadata is double in my harvester. This is the quickest and dirtiest fix -->

	<xsl:template match="/">
			<xsl:apply-templates
				select="/oai:OAI-PMH/oai:GetRecord/oai:record/oai:metadata/oai:metadata/*" />
			<xsl:apply-templates
				select="/oai:OAI-PMH/oai:ListRecords/oai:record/oai:metadata/oai:metadata/*" />
	</xsl:template>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>