<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.loc.gov/mods/v3"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.loc.gov/mods/v3">
   <xsl:output method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" name="text"/>
    <!-- this stylesheet generates a MODS XML file with bibliographic metadata for each <div> in the body of the TEI source file. File names are based on the source's @xml:id and the @xml:id of the <div>. -->
    <xsl:include href="convert_tei-to-biblstruct_functions.xsl"/>
    <xsl:include href="convert_tei-to-csv_functions.xsl"/>
    
    <xsl:template match="/">
        <xsl:result-document href="../metadata/issues/{$vgFileId}.csv" method="text">
            <xsl:value-of select="$v_csv-head"/>
            <xsl:value-of select="$v_new-line"/>
                <!-- construct CSV -->
                <xsl:apply-templates select="descendant::tei:text/tei:body/descendant::tei:div"/>
        </xsl:result-document>
    </xsl:template>
    <xsl:template match="tei:div">
        <xsl:choose>
            <!-- prevent output for sections of legal texts -->
            <xsl:when
                test="ancestor::tei:div[@type = 'bill'] or ancestor::tei:div[@subtype = 'bill']"/>
            <!-- prevent output for sections of articles -->
            <xsl:when test="parent::tei:div[@type = 'item']"/>
            <!-- prevent output for mastheads -->
            <xsl:when test="@type = 'item' and @subtype = 'masthead'"/>
            <xsl:when test="@type = ('section', 'item')">
                <xsl:copy-of select="oape:bibliography-tei-to-csv(oape:bibliography-tei-div-to-biblstruct(.))"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
