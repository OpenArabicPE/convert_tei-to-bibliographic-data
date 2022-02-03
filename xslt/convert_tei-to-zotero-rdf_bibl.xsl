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
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    <xsl:preserve-space elements="tei:head tei:bibl"/>

    <xsl:include href="convert_tei-to-zotero-rdf_functions.xsl"/>
    <xsl:include href="parameters.xsl"/>
    
    <!-- it doesn't matter if one applies the transformation to bibl or biblStruct -->
    <xsl:template match="tei:bibl | tei:biblStruct">
        <xsl:copy-of select="oape:bibliography-tei-to-zotero-rdf(., $p_target-language)"/>
    </xsl:template>

    <xsl:template match="/">
        <xsl:result-document href="../metadata/{$vgFileId}-bibl.Zotero.rdf">
            <rdf:RDF>
                <!--<xsl:apply-templates select=".//tei:body//tei:bibl[contains(ancestor::tei:div/tei:head/text(),$pg_head-section)]"/>-->
                <xsl:apply-templates select=".//tei:body//tei:bibl[descendant::tei:title] | .//tei:body//tei:biblStruct"/>
                <!-- apply to the works listed in the particDesc -->
                <xsl:apply-templates select=".//tei:standOff//tei:biblStruct"/>
            </rdf:RDF>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>