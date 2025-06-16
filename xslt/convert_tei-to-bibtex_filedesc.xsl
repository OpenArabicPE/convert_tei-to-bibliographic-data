<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:cc="http://web.resource.org/cc/" xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <xsl:preserve-space elements="tei:head tei:bibl"/>
    
<!--    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>-->
    <xsl:import href="convert_tei-to-bibtex_functions.xsl"/>
    
    <xsl:template match="/">
        <!-- convert fileDesc to biblStruct -->
        <xsl:variable name="v_biblStruct">
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="tei:TEI/tei:teiHeader/tei:fileDesc"/>
        </xsl:variable>
        <!-- convert biblStruct to BibTeX -->
        <xsl:result-document href="{$v_base-directory}metadata/file/{$v_file-name_input}.bib" method="text">
                <xsl:copy-of select="oape:bibliography-tei-to-bibtex($v_biblStruct/child::tei:biblStruct, $p_target-language)"/>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
