<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <xsl:import href="convert_tei-to-bibtex_functions.xsl"/>
    <xsl:import href="convert_tei-to-yaml_functions.xsl"/>
    <xsl:import href="convert_tei-to-mods_functions.xsl"/>
    <xsl:import href="convert_tei-to-zotero-rdf_functions.xsl"/>
    
    <xsl:variable name="v_output-path" select="concat(base-uri(),'/../', 'output')"/>
    
    <!-- all parameters and variables are set in convert_tei-to-mods_functions.xsl -->
    <xsl:template match="/">
        <xsl:message>
            <xsl:value-of select="$v_output-path"/>
        </xsl:message>
        <xsl:apply-templates select="descendant::tei:text/tei:body/descendant::tei:div" mode="m_debug"/>
    </xsl:template>
    <xsl:template match="tei:div" mode="m_debug">
        <xsl:variable name="v_biblStruct" select="oape:bibliography-tei-div-to-biblstruct(.)"/>
        <xsl:variable name="v_bibtex" select="oape:bibliography-tei-to-bibtex($v_biblStruct, @xml:lang)"/>
        <xsl:variable name="v_yaml" select="oape:bibliography-tei-to-yaml($v_biblStruct, @xml:lang, true())"/>
        <xsl:variable name="v_mods" select="oape:bibliography-tei-to-mods($v_biblStruct, @xml:lang)"/>
        <xsl:variable name="v_zotero" select="oape:bibliography-tei-to-zotero-rdf($v_biblStruct, @xml:lang)"/>
        <!-- output -->
        <xsl:result-document href="{$v_output-path}/{$v_file-name_input}_biblStruct.TEIP5.xml" method="xml">
            <xsl:copy-of select="$v_biblStruct"/>
        </xsl:result-document>
        <xsl:result-document href="{$v_output-path}/{$v_file-name_input}.bib" method="text">
            <xsl:copy-of select="$v_bibtex"/>
        </xsl:result-document>
        <xsl:result-document href="{$v_output-path}/{$v_file-name_input}.yml" method="text">
            <xsl:copy-of select="$v_yaml"/>
        </xsl:result-document>
        <xsl:result-document href="{$v_output-path}/{$v_file-name_input}.MODS.xml" method="xml">
            <xsl:copy-of select="$v_mods"/>
        </xsl:result-document>
        <xsl:result-document href="{$v_output-path}/{$v_file-name_input}.Zotero.rdf" method="xml">
            <xsl:copy-of select="$v_zotero"/>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>