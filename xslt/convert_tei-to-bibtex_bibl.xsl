<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:cc="http://web.resource.org/cc/" xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:preserve-space elements="tei:head tei:bibl"/>
    <!--    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>-->
    <xsl:import href="convert_tei-to-bibtex_functions.xsl"/>
    <!-- it doesn't matter if one applies the transformation to bibl or biblStruct -->
    <xsl:template match="tei:bibl | tei:biblStruct">
        <xsl:copy-of select="oape:bibliography-tei-to-bibtex(., $p_target-language)"/>
    </xsl:template>
    <xsl:template match="/">
        <!-- convert biblStruct to BibTeX -->
        <xsl:result-document href="{$p_output-folder}{$v_file-name_input}-bibl.bib" method="text">
            <xsl:apply-templates select="descendant::tei:standOff//tei:biblStruct"/>
            <!--<xsl:apply-templates select=".//tei:body//tei:bibl[contains(ancestor::tei:div/tei:head/text(),$pg_head-section)]"/>-->
            <xsl:apply-templates select="descendant::tei:text//tei:bibl[descendant::tei:title] | .//tei:body//tei:biblStruct"/>
            <!-- apply to the works listed in the particDesc -->
            <xsl:apply-templates select="descendant::tei:particDesc//tei:bibl[descendant::tei:title]"/>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
