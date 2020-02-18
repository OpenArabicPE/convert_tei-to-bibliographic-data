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
<!--        <xsl:apply-templates select="$tss_note/tss:pages" mode="m_tss-to-notes-html"/>-->
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

    <!-- map reference types -->
    <xsl:variable name="v_reference-types">
        <tei:listNym>
            <tei:nym>
                <tei:form n="tss">Archival Book Chapter</tei:form>
                <tei:form n="zotero">bookSection</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">BookSection</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival File</tei:form>
                <tei:form n="zotero">manuscript</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Manuscript</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Journal Entry</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Letter</tei:form>
                <tei:form n="zotero">letter</tei:form>
                <tei:form n="marcgt">letter</tei:form>
                <tei:form n="bib">Letter</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Material</tei:form>
                <tei:form n="zotero">manuscript</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Manuscript</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Periodical</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt">periodical</tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Periodical Article</tei:form>
                <tei:form n="zotero">magazineArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-magazine</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Bill</tei:form>
                <tei:form n="zotero">bill</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Legislation</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Book</tei:form>
                <tei:form n="zotero">book</tei:form>
                <tei:form n="marcgt">book</tei:form>
                <tei:form n="bib">Book</tei:form>
                <tei:form n="biblatex">mvbook</tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Book Chapter</tei:form>
                <tei:form n="zotero">bookSection</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">BookSection</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Computer Software</tei:form>
                <tei:form n="zotero">Computer Programme</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Edited Book</tei:form>
                <tei:form n="zotero">book</tei:form>
                <tei:form n="marcgt">book</tei:form>
                <tei:form n="bib">Book</tei:form>
                <tei:form n="biblatex">mvbook</tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Electronic Citation</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Journal Article</tei:form>
                <tei:form n="zotero">journalArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-journal</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Manuscript</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Maps</tei:form>
                <tei:form n="zotero">map</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Image</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Motion Picture</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Newspaper article</tei:form>
                <tei:form n="zotero">newspaperArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-newspaper</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Other</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Photograph</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Web Page</tei:form>
                <tei:form n="zotero">Web Page</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
        </tei:listNym>
    </xsl:variable>
    
    <!-- this function checks, if one needs to switch volume and issue information based on a periodical's title -->
    <xsl:function name="oape:bibliography-tss-switch-volume-and-issue">
        <xsl:param name="tss_reference"/>
        <xsl:variable name="v_title-short" select=" lower-case($tss_reference/descendant::tss:characteristic[@name = 'Short Titel'])"/>
        <xsl:choose>
            <xsl:when test="$v_title-short = ('lisān')">
                <xsl:copy-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>