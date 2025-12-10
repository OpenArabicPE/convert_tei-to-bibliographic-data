<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:417'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- to do
        - hamza, ayn
        - commas in Arabic strings
    -->
    <!--<xsl:template mode="m_post-process" match="tei:bibl[tei:idno[starts-with(., 'https://hdl.handle.net/2027/')]]" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="type" select="'copy'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>-->
    <!-- switch off post processing for notes -->
    <xsl:template match="tei:note" mode="m_off">
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
    <xsl:template match="tei:title[ends-with(., '=')][following-sibling::tei:title[@type = 'sub']]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '\s*=$', '')"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[@type = 'sub'][preceding-sibling::tei:title[ends-with(., '=')]]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@level | @xml:lang"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblScope[ancestor::tei:note[@type = 'holdings']]" mode="m_off">
        <xsl:choose>
            <xsl:when test="matches(., '\(.+\)')">
                <xsl:variable name="v_date" select="replace(., '^(.*)\((.+)\)(.*)$', '$2')"/>
                <xsl:variable name="v_remainder" select="replace(., '^(.*)\((.+)\)(.*)$', '$1$3')"/>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:value-of select="normalize-space($v_remainder)"/>
                </xsl:copy>
                <date>
                    <xsl:value-of select="$v_date"/>
                </date>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:date[not(@type)][matches(., '^(.*\w{4})-([^i]+.*)$')]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:attribute name="type" select="'onset'"/>
            <xsl:value-of select="replace(., '^(.*\w{4})-([^i]+.*)$', '$1')"/>
        </xsl:copy>
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:attribute name="type" select="'terminus'"/>
            <xsl:value-of select="replace(., '^(.*\w{4})-([^i]+.*)$', '$2')"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
