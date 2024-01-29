<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:zot="https://zotero.org" xmlns:cpc="http://copac.ac.uk/schemas/mods-copac/v1"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    
    <!-- to do
        - hyphens in most notes
        - textLang: 
            - write values to attributes
        - editor
            - wrap content in persName
            - possibly split into multiple entries
       - note: sources
            - wrap all constituent parts in ref
    -->
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- split textLang -->
    <!--<xsl:template match="tei:textLang[contains(., ',')]">
        <xsl:for-each select="tokenize(., ',')">
            <textLang>
                <xsl:value-of select="normalize-space(.)"/>
            </textLang>
        </xsl:for-each>
    </xsl:template>-->
    <!--<xsl:template match="tei:textLang[string-length(text()) = 2]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="mainLang" select="lower-case(.)"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>-->
    <!-- dates -->
    <xsl:template match="tei:date">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="matches(., '^\s*\d{1,2}/\d{4}')">
                <xsl:variable name="v_year" select="replace(., '^\s*(\d{1,2})/(\d{4})\s.+$', '$2')"/>
                <xsl:variable name="v_month" select="number(replace(., '^\s*(\d{1,2})/(\d{4})\s.+$', '$1'))"/>
                <xsl:variable name="v_day">
                    <xsl:choose>
                        <xsl:when test="$v_month = (1,3,5,7,8,10,12)">
                            <xsl:value-of select="31"/>
                        </xsl:when>
                        <xsl:when test="$v_month = 2">
                            <xsl:value-of select="28"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="30"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="v_month" select="format-number($v_month, '00')"/>
                <xsl:attribute name="notBefore" select="concat($v_year, '-', $v_month, '-01')"/>
                <xsl:attribute name="notAfter" select="concat($v_year, '-', $v_month, '-', $v_day)"/>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!--<xsl:template match="tei:date/tei:date">
        <xsl:value-of select="."/>
    </xsl:template>-->
    <!--<xsl:template match="tei:note[@type = ('ps', 'o')]/text() | tei:placeName/text() | tei:bibl/text()">
        <xsl:value-of select="replace(., '(\w)-(\w)', '$1$2')"/>
    </xsl:template>-->
    <!-- compile notes -->
    <!--<xsl:template match="tei:note[@type = 'sources']">
         <xsl:copy>
            <xsl:attribute name="type" select="'comments'"/>
            <list>
                <xsl:apply-templates select="parent::tei:bibl//tei:note[not(@type = 'sources')]" mode="m_note-to-item"/>
            </list>
        </xsl:copy>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template mode="m_note-to-item" match="tei:note">
        <item>
            <xsl:apply-templates select="@* | node()"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:note[not(@type = 'sources')]"/>-->
</xsl:stylesheet>