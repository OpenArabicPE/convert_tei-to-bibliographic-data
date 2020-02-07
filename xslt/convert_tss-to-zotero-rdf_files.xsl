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
  xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:oape="https://openarabicpe.github.io/ns"
    version="3.0">
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    <xsl:include href="convert_tss-to-zotero-rdf_functions.xsl"/>
    
    <xsl:variable name="v_file-name" select="substring-before(tokenize(base-uri(),'/')[last()],'.TSS.xml')"/>
    
    <!-- debugging -->
    <xsl:template match="/">
        <xsl:result-document href="{$v_file-name}.ZOTERO.rdf">
            <rdf:RDF>
                <xsl:apply-templates select="descendant::tss:reference" mode="m_tss-to-zotero-rdf"/>
            </rdf:RDF>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="tss:reference" mode="m_tss-to-zotero-rdf">
         <xsl:copy-of select="oape:bibliography-tss-to-zotero-rdf(.)"/>
    </xsl:template>
</xsl:stylesheet>