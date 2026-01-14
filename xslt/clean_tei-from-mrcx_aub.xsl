<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:73'"/>
    <xsl:template match="tei:biblStruct[not(@type)]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:if test="not(@type)">
                <xsl:attribute name="type" select="'periodical'"/>
            </xsl:if>
            <xsl:if test="not(@subtype) and descendant::tei:title[matches(., 'مجلة|جريدة')]">
                <xsl:attribute name="subtype">
                    <xsl:choose>
                        <xsl:when test="matches(., 'مجلة')">
                            <xsl:text>journal</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., 'جريدة')">
                            <xsl:text>newspaper</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!--<xsl:template match="tei:item[not(tei:label)][ancestor::tei:note/@type = 'holdings']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="label">
                <xsl:element name="rs">
                    <xsl:attribute name="ref" select="'#hAUB'"/>
                    <xsl:attribute name="xml:lang" select="'en'"/>
                    <xsl:text>AUB</xsl:text>
                </xsl:element>
            </xsl:element>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>-->
    <xsl:template match="@xml:lang[. = 'und']" mode="m_off">
        <xsl:attribute name="xml:lang" select="'ar'"/>
    </xsl:template>
    <xsl:template match="tei:monogr[preceding-sibling::tei:analytic]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="preceding-sibling::tei:analytic/tei:title"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:analytic" mode="m_off"/>
    <xsl:template match="text()[matches(., '^\[.+\]$')]" mode="m_off">
        <xsl:element name="supplied">
            <xsl:attribute name="resp" select="'#aub'"/>
            <xsl:value-of select="replace(., '^\[(.+)\]$', '$1')"/>
        </xsl:element>
    </xsl:template>
    <!-- parse holding information from the free-text comment field -->
    <xsl:template match="tei:bibl[not(@resp = '#xslt')][ancestor::tei:note[@type = 'holdings']]" mode="m_post-process">
        <xsl:variable name="v_ids" select="tei:idno"/>
        <xsl:choose>
            <!-- 1. split along '؛ ' -->
            <xsl:when test="contains(., '؛ ')">
                <xsl:message terminate="yes"/>
            </xsl:when>
            <!-- parse dates -->
        </xsl:choose>
    </xsl:template>
    
    
</xsl:stylesheet>
