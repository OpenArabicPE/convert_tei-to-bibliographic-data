<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:z="http://www.zotero.org/namespaces/export#"
 xmlns:bib="http://purl.org/net/biblio#"
 xmlns:foaf="http://xmlns.com/foaf/0.1/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:vcard="http://nwalsh.com/rdf/vCard#"
  xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" 
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:link="http://purl.org/rss/1.0/modules/link/"
  xmlns:oape="https://openarabicpe.github.io/ns"
  exclude-result-prefixes="tei tss"
    version="3.0">
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    
    <!-- plain text output   -->
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="element()" mode="m_plain-text">
        <xsl:apply-templates mode="m_plain-text"/>
    </xsl:template>
    <xsl:template match="text()[matches(.,'^\s+$')]" mode="m_plain-text" priority="10"/>
    <xsl:template match="text()" mode="m_plain-text">
<!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <xsl:template match="text()[not(ancestor::tei:choice)][preceding-sibling::node()]" mode="m_plain-text">
        <xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <!--<xsl:template match="text()[not(ancestor::tei:choice)][following-sibling::node()]" mode="m_plain-text">
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text> </xsl:text>
    </xsl:template>-->   
    <!-- choice -->
    <xsl:template match="tei:choice" mode="m_plain-text">
        <xsl:choose>
            <xsl:when test="tei:abbr and tei:expan">
                <xsl:apply-templates select="tei:expan" mode="m_plain-text"/>
            </xsl:when>
            <xsl:when test="tei:orig">
                <xsl:apply-templates select="tei:orig" mode="m_plain-text"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- replace any line, column or page break with a single whitespace -->
    <xsl:template match="tei:lb | tei:cb | tei:pb" mode="m_plain-text">
        <xsl:text> </xsl:text>
    </xsl:template>
    <!-- prevent notes in div/head from producing output -->
    <xsl:template match="tei:head/tei:note" mode="m_plain-text" priority="100"/>
</xsl:stylesheet>