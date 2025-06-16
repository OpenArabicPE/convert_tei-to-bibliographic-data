<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <xsl:output method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" name="text"/>
    <xsl:strip-space elements="*"/>

    <!-- this stylesheet generates a Bibtex file with bibliographic metadata for each <div> in the body of the TEI source file. File names are based on the source's @xml:id and the @xml:id of the <div>. -->
    <!-- to do:
        + add information on edition: i.e. TEI edition
        + add information on collaborators on the digital edition
        comment: this information cannot be added to BibTeX for articles appart from the generic "annote" tag -->
    
    <xsl:include href="convert_tei-to-bibtex_functions.xsl"/>

    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}{$p_output-folder}{$v_file-name_input}.bib" method="text">
            <xsl:call-template name="t_file-head"/>
            <!-- construct BibText -->
            <xsl:apply-templates select="descendant::tei:text/tei:body/descendant::tei:div"/>
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
                   <xsl:copy-of select="oape:bibliography-tei-to-bibtex(oape:bibliography-tei-div-to-biblstruct(.), $p_target-language)"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
