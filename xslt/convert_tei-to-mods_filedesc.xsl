<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:cc="http://web.resource.org/cc/" xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    <xsl:preserve-space elements="tei:head tei:bibl"/>
    
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <xsl:import href="convert_tei-to-mods_functions.xsl"/>
    
    <xsl:template match="/">
        <!-- convert fileDesc to biblStruct -->
        <xsl:variable name="v_biblStruct">
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="tei:TEI/tei:teiHeader/tei:fileDesc"/>
        </xsl:variable>
        <!-- convert biblStruct to MODS -->
        <xsl:result-document href="{$v_base-directory}metadata/file/{$v_id-file}.MODS.xml" method="xml">
            <xsl:value-of disable-output-escaping="yes" select="concat('&lt;?xml-model href=&quot;', $v_schema, '&quot;?&gt;')"/>
            <modsCollection xmlns="http://www.loc.gov/mods/v3" xsi:schemaLocation="{$v_schema}">
                <xsl:copy-of select="oape:bibliography-tei-to-mods($v_biblStruct/child::tei:biblStruct, $p_target-language)"/>
            </modsCollection>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
