<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns="http://www.loc.gov/mods/v3"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xpath-default-namespace="http://www.loc.gov/mods/v3" 
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    <xsl:preserve-space elements="tei:head tei:bibl"/>

    <xsl:import href="convert_tei-to-mods_functions.xsl"/>
    
    <!-- this parameter is currently not used -->
<!--    <xsl:param name="pg_head-section" select="'مخطوطات ومطبوعات'"/>-->
    <!--  -->
    <xsl:param name="p_url-boilerplate" select="'../xslt-boilerplate/modsbp_parameters.xsl'"/>
    
    <!-- it doesn't matter if one applies the transformation to bibl or biblStruct -->
    <xsl:template match="tei:bibl | tei:biblStruct">
        <xsl:copy-of select="oape:bibliography-tei-to-mods(., $p_target-language)"/>
    </xsl:template>

    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}{$p_output-folder}{$v_file-name_input}-bibl.MODS.xml">
            <xsl:value-of select="concat('&lt;?xml-stylesheet type=&quot;text/xsl&quot; href=&quot;',$p_url-boilerplate,'&quot;?&gt;')" disable-output-escaping="yes"/>
            <xsl:value-of select="concat('&lt;?xml-model href=&quot;',$v_schema,'&quot;?&gt;')" disable-output-escaping="yes"/>
            <modsCollection xsi:schemaLocation="{$v_schema}">
                <xsl:apply-templates select="descendant::tei:standOff//tei:biblStruct"/>
                <!--<xsl:apply-templates select=".//tei:body//tei:bibl[contains(ancestor::tei:div/tei:head/text(),$pg_head-section)]"/>-->
                <xsl:apply-templates select="descendant::tei:text//tei:bibl[descendant::tei:title] | .//tei:body//tei:biblStruct"/>
                <!-- apply to the works listed in the particDesc -->
                <xsl:apply-templates select="descendant::tei:particDesc//tei:bibl[descendant::tei:title]"/>
            </modsCollection>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>
