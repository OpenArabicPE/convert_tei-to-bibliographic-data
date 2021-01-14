<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet generates a TEI XML file with bibliographic metadata for each <div> in the body of the TEI source file. File names are based on the source's @xml:id and the @xml:id of the <div>. -->
    <xsl:include href="convert_tei-to-biblstruct_functions.xsl"/>
    
    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}metadata/{$vgFileId}.biblStruct.TEIP5.xml">
            <xsl:copy>
                <xsl:element name="TEI">
                    <xsl:copy-of select="tei:TEI/tei:teiHeader"/>
                    <xsl:element name="standOff">
                        <xsl:element name="listBibl">
                             <xsl:apply-templates select="descendant::tei:text/tei:body/descendant::tei:div"/>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:copy>
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
                <xsl:copy-of select="oape:bibliography-tei-div-to-biblstruct(.)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
