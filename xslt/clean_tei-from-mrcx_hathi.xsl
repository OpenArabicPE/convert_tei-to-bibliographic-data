<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- to do
        - hamza, ayn
        - commas in Arabic strings
    -->
    <!-- switch off post processing for notes -->
    <xsl:template match="tei:note" mode="m_post-process">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="tei:forename[@xml:lang = 'ar'] | tei:surname[@xml:lang = 'ar']" mode="m_off" priority="10">
        <xsl:value-of select="."/>
    </xsl:template>
    <!-- remove erroneous automated transcriptions -->
    <xsl:template match="element()[@xml:lang = 'ar'][@resp = '#xslt']" mode="m_off"/>
    <xsl:template match="tei:title[@ref][@resp = '#xslt']" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@xml:lang | @level | @type | @change"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <!-- remove all orgs which are already part of the organizationography -->
    <xsl:template match="tei:org[parent::tei:listOrg][tei:orgName[@ref]]" mode="m_off"/>
    <!-- dates-->
    <!-- titles ending in = -->
    <xsl:template match="tei:title[ends-with(., '=')][following-sibling::tei:title[@type = 'sub']]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '\s*=$', '')"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[@type = 'sub'][preceding-sibling::tei:title[ends-with(., '=')]]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@level | @xml:lang"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
