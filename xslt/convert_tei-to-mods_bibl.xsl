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

    <xsl:include href="convert_tei-to-mods_functions.xsl"/>
    
    <!-- this parameter is currently not used -->
<!--    <xsl:param name="pg_head-section" select="'مخطوطات ومطبوعات'"/>-->
    <!--  -->
    <xsl:param name="p_url-boilerplate" select="'../xslt-boilerplate/modsbp_parameters.xsl'"/>
    <xsl:param name="p_target-language" select="'ar'"/>
    
    <!-- it doesn't matter if one applies the transformation to bibl or biblStruct -->
    <xsl:template match="tei:bibl | tei:biblStruct">
        <!--<xsl:variable name="v_type">
            <xsl:choose>
                <xsl:when test="descendant::tei:title/@level = 'm'">
                    <xsl:text>m</xsl:text>
                </xsl:when>
                <xsl:when test="descendant::tei:title/@level = 'a'">
                    <xsl:text>a</xsl:text>
                </xsl:when>
                <xsl:when test="descendant::tei:title/@level = 'j'">
                    <xsl:text>j</xsl:text>
                </xsl:when>
                <xsl:when test="descendant::tei:title/@level = 's'">
                    <xsl:text>m</xsl:text>
                </xsl:when>
                <!-\- fallback option -\->
                <!-\-<xsl:otherwise>
                    <xsl:text>m</xsl:text>
                </xsl:otherwise>-\->
            </xsl:choose>
        </xsl:variable>-->
        <xsl:copy-of select="oape:bibliography-tei-to-mods(., $p_target-language)"/>
    </xsl:template>

    <xsl:template match="/">
        <xsl:result-document href="../metadata/{$vgFileId}-bibl.MODS.xml">
            <xsl:value-of select="concat('&lt;?xml-stylesheet type=&quot;text/xsl&quot; href=&quot;',$p_url-boilerplate,'&quot;?&gt;')" disable-output-escaping="yes"/>
            <modsCollection xsi:schemaLocation="{$v_schema}">
                <!--<xsl:apply-templates select=".//tei:body//tei:bibl[contains(ancestor::tei:div/tei:head/text(),$pg_head-section)]"/>-->
                <xsl:apply-templates select=".//tei:body//tei:bibl[descendant::tei:title] | .//tei:body//tei:biblStruct"/>
                <!-- apply to the works listed in the particDesc -->
                <xsl:apply-templates select=".//tei:particDesc//tei:bibl[descendant::tei:title]"/>
            </modsCollection>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>
