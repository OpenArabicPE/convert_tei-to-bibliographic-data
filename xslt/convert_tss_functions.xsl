<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns="http://www.loc.gov/mods/v3"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.loc.gov/mods/v3"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    
     <xsl:function name="oape:bibliography-tss-note-to-html">
        <!-- expects a <tss:note> as input -->
        <xsl:param name="tss_note"/>
        <xsl:apply-templates select="$tss_note/tss:pages" mode="m_tss-to-notes-html"/>
        <xsl:apply-templates select="$tss_note/tss:title" mode="m_tss-to-notes-html"/>
        <xsl:apply-templates select="$tss_note/tss:pages" mode="m_tss-to-notes-html"/>
        <xsl:apply-templates select="$tss_note/tss:quotation" mode="m_tss-to-notes-html"/>
        <xsl:apply-templates select="$tss_note/tss:comment" mode="m_tss-to-notes-html"/>
    </xsl:function>
    
    <xsl:template match="tss:title" mode="m_tss-to-notes-html">
        <![CDATA[<h1>]]><xsl:text># </xsl:text><xsl:apply-templates/><![CDATA[</h1>]]>
    </xsl:template>
    <xsl:template match="tss:pages" mode="m_tss-to-notes-html">
        <![CDATA[<span>]]><xsl:text>(p.</xsl:text><xsl:apply-templates/><xsl:text>)</xsl:text><![CDATA[</span>]]>
    </xsl:template>
    <xsl:template match="tss:quotation" mode="m_tss-to-notes-html">
        <![CDATA[<blockquote style="background-color:]]><xsl:value-of select="parent::tss:note/@color"/><![CDATA[">]]>
            <![CDATA[<p>]]><xsl:text>></xsl:text><xsl:apply-templates/><![CDATA[</p>]]>
        <![CDATA[</blockquote>]]>
    </xsl:template>
    <xsl:template match="tss:comment" mode="m_tss-to-notes-html">
        <![CDATA[<p>]]><xsl:apply-templates/><![CDATA[</p>]]>
    </xsl:template>
</xsl:stylesheet>