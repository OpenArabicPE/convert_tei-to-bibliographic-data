<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:60'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- add templates specific to this particular input -->
    <!-- switch off post processing for notes -->
    <xsl:template match="tei:note" mode="m_off">
        <xsl:copy-of select="."/>
    </xsl:template>
    <!-- postprocessing specific to JISC -->
    <!-- delete all elements, which have no value -->
    <xsl:template match="element()[. = 's.n.']" mode="m_post-process" priority="22"/>
    <!-- remove trailing punctuation marks -->
    <xsl:template match="tei:title | tei:orgName | tei:placeName" mode="m_off" priority="20">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:choose>
                <xsl:when test="matches(., '\s*\.{2}\s*$')">
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:when>
                <!--<xsl:when test="matches(., '^\s*[\.\]]\s*')">
                    <xsl:value-of select="replace(., '(\s*[\.\]]\s*)', '')"/>
                </xsl:when>
-->
                <xsl:when test="matches(., '\s*[\.]\s*$')">
                    <xsl:value-of select="replace(., '(\s*[\.]\s*)$', '')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!-- transcription:
           - initial hamza
           - ʻ for ʿayn
    -->
    <!-- correct level -->
    <xsl:template match="tei:monogr/tei:title[@level = 'a']" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="level" select="'j'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:forename/text()" mode="m_post-process">
        <xsl:value-of select="replace(., '(\s*\.)$', '')"/>
    </xsl:template>
    <xsl:template match="tei:textLang[parent::tei:monogr/tei:title[contains(., 'سالنامه')]]" mode="m_post-process">
        <xsl:copy>
            <xsl:attribute name="mainLang" select="'ota'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[matches(., '^.+\[.+\]$')]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '(\s*\[.+\])$', '')"/>
        </xsl:copy>
        <note type="temp">
            <xsl:value-of select="replace(., '^(.+\s)*\[(.+)\]$', '$2')"/>
        </note>
    </xsl:template>
    <!-- remove all orgs which are already part of the organizationography -->
    <xsl:template match="tei:org[parent::tei:listOrg][tei:orgName[@ref]]" mode="m_off"/>
    <xsl:template match="@when | @notBefore | @notAfter" mode="m_post-process" priority="20">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="oape:transpose-digits(., 'arabic', 'western')"/>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>
