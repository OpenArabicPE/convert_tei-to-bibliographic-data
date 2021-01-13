<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
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
    xpath-default-namespace="http://www.loc.gov/mods/v3">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet generates a MODS XML file with bibliographic metadata for each <div> in the body of the TEI source file. File names are based on the source's @xml:id and the @xml:id of the <div>. -->
    <xsl:include href="convert_tei-to-biblstruct_functions.xsl"/>
    <xsl:include href="convert_tei-to-zotero-rdf_functions.xsl"/>
    
    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}metadata/issues/{$vgFileId}.Zotero.rdf">
            <rdf:RDF>
                <!-- construct RDF -->
                <xsl:apply-templates select="descendant::tei:text/tei:body/descendant::tei:div"/>
            </rdf:RDF>
        </xsl:result-document>
    </xsl:template>
    <xsl:template match="tei:div">
        <xsl:choose>
             <!-- prevent output for sections of legal texts -->
            <xsl:when test="ancestor::tei:div[@type = 'bill'] or ancestor::tei:div[@subtype = 'bill']"/>
            <!-- prevent output for mastheads -->
            <xsl:when test="@type='masthead' or @subtype='masthead'"/>
            <!-- prevent output for sections of articles -->
            <xsl:when test="ancestor::tei:div[@type='item']"/>
            <xsl:when test="@type = ('section', 'item')">
                <xsl:copy-of select="oape:bibliography-tei-to-zotero-rdf(oape:bibliography-tei-div-to-biblstruct(.), $p_target-language)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
