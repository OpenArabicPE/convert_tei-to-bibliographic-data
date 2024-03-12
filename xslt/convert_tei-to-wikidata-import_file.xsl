<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.wikidata.org/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:import href="convert_tei-to-wikidata-import_functions.xsl"/>
    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}metadata/{$v_file-name_input}.Wikidata.xml">
            <items>
                <xsl:apply-templates select="descendant::tei:biblStruct"/>
            </items>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
