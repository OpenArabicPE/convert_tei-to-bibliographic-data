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
    <!-- transcription:
           - initial hamza
           - ʻ for ʿayn
    -->
    <!-- remove online holdings -->
    <xsl:template match="tei:item[ancestor::tei:note[@type = 'holdings']][descendant::tei:note[@type = 'format'][matches(., '^(online|electronic)')]]" mode="m_post-process"/>
    <!-- partial dates -->
    <xsl:template match="tei:imprint/tei:date[matches(., '^1\du+$')]" mode="m_post-process" priority="30">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:attribute name="notBefore" select="concat(replace(., '^(1\d)u+$', '$1'), '00-01-01')"/>
            <xsl:attribute name="notAfter" select="concat(replace(., '^(1\d)u+$', '$1'), '99-12-01')"/>
            <xsl:attribute name="cert" select="'low'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
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
