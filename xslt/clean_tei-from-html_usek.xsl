<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:567'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- add templates specific to this particular input -->
    <!-- information to be removed as I do not further process it -->
    <xsl:template match="tei:idno[@type = 'url'][starts-with(., '/search?/')]"/>
    <xsl:template match="tei:biblScope[not(@unit)]"/>
    <xsl:template match="tei:idno[@type = 'URI']">
        <xsl:copy>
            <xsl:attribute name="type" select="'url'"/>
            <xsl:attribute name="subtype" select="'permalink'"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
