<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <xsl:output method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" name="text"/>
    <xsl:strip-space elements="*"/>
    
    <!-- this stylesheet translates <tei:biblStruct>s to  BibTeX -->
    
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="vgFileId" select="substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5')"/>
    
    <xsl:function name="oape:bibliography-tei-to-bibtex">
        <!-- input is a bibl or biblStruct -->
        <xsl:param name="p_input"/>
        <!-- output language -->
        <xsl:param name="p_lang"/>
        <!-- missing bits: absent from biblStruct
            - licence
            - date last accessed
            - edition
        -->
        <xsl:variable name="v_bibtex-key" select="$p_input/tei:analytic/tei:idno[@type='BibTeX']"/>
        <xsl:variable name="v_publication-date">
            <xsl:choose>
                <xsl:when test="$p_input/descendant::tei:date[string-length(@when) = 10]">
                    <xsl:copy-of select="$p_input/descendant::tei:date[string-length(@when) = 10][1]"/>
                </xsl:when>
                <xsl:when test="$p_input/descendant::tei:date[@when]">
                    <xsl:copy-of select="$p_input/descendant::tei:date[@when][1]"/>
                </xsl:when>
                <!-- some fallback -->
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>
         <!-- construct BibText -->
            <xsl:text>@ARTICLE{</xsl:text>
            <!-- BibTextKey -->
            <xsl:value-of select="$v_bibtex-key"/><xsl:text>, </xsl:text><xsl:value-of select="$v_new-line"/>
            <!-- author information -->
            <xsl:if test="$p_input/descendant::tei:author">
                <xsl:text>author = {</xsl:text>
                <xsl:apply-templates select="$p_input/descendant::tei:author/tei:persName[@xml:lang = $p_lang]" mode="m_tei-to-bibtex"/>
                <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
            </xsl:if>
            <!-- editor information -->
            <xsl:text>editor = {</xsl:text>
            <xsl:apply-templates select="$p_input/descendant::tei:editor/tei:persName[@xml:lang = $p_lang]" mode="m_tei-to-bibtex"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
            <!-- titles -->
            <xsl:text>title = {</xsl:text>
            <xsl:value-of select="$p_input/descendant::tei:title[@level = 'a'][@xml:lang = $p_lang]"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
            <xsl:text>journal = {</xsl:text>
            <xsl:value-of select="$p_input/descendant::tei:title[@level = 'j'][@xml:lang = $p_lang]"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
            <!-- imprint -->
            <xsl:apply-templates select="$p_input/descendant::tei:biblScope" mode="m_tei-to-bibtex"/>
        <xsl:apply-templates select="$p_input/descendant::tei:publisher/node()[@xml:lang = $p_lang]" mode="m_tei-to-bibtex"/>
        <xsl:text>address = {</xsl:text>
            <xsl:apply-templates select="$p_input/descendant::tei:pubPlace/tei:placeName[@xml:lang = $p_lang]" mode="m_tei-to-bibtex"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
        <xsl:apply-templates select="$p_input/descendant::tei:textLang" mode="m_tei-to-bibtex"/>
            <!-- publication dates -->
            <xsl:apply-templates select="$v_publication-date/tei:date" mode="m_tei-to-bibtex"/>
            <!-- URL -->
            <xsl:text>url = {</xsl:text>
            <xsl:value-of select="$p_input/descendant::tei:idno[@type = 'url'][1]"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
            <!-- add information on digital edition as a note -->
            <xsl:text>annote = {</xsl:text>
            <xsl:text>digital TEI edition, </xsl:text><xsl:value-of select="year-from-date(current-date())"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
            <xsl:text>}</xsl:text><xsl:value-of select="$v_new-line"/>
    </xsl:function>
    
     <xsl:template match="tei:lb | tei:cb | tei:pb" mode="m_tei-to-bibtex">
        <xsl:text> </xsl:text>
    </xsl:template>

    <!-- prevent notes in div/head from producing output -->
    <xsl:template match="tei:head/tei:note" mode="m_tei-to-bibtex"/>
    <xsl:template match="tei:head" mode="m_tei-to-bibtex">
        <xsl:apply-templates mode="m_tei-to-bibtex"/>
    </xsl:template>
    
    <!-- authors -->
    <xsl:template  match="tei:persName" mode="m_tei-to-bibtex">
        <xsl:choose>
            <xsl:when test="tei:surname and tei:forename">
               <xsl:apply-templates select="tei:surname" mode="m_tei-to-bibtex"/>
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="tei:forename" mode="m_tei-to-bibtex"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_tei-to-bibtex">
                <xsl:value-of select="replace(.,'[\s|\n]+',' ')"/>
    </xsl:template>
    
    <xsl:template match="tei:biblScope" mode="m_tei-to-bibtex">
        <xsl:choose>
            <xsl:when test="@unit = 'volume'">
                <xsl:text>volume = {</xsl:text>
            </xsl:when>
            <xsl:when test="@unit = 'issue'">
                <xsl:text>number = {</xsl:text>
            </xsl:when>
            <xsl:when test="@unit = 'page'">
                <xsl:text>pages = {</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="@from = @to">
                <xsl:value-of select="@from"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(@from, '-', @to)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
    </xsl:template>
    
    <xsl:template match="tei:publisher/node()" mode="m_tei-to-bibtex">
     <xsl:text>publisher = {</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>   
    </xsl:template>
    <xsl:template match="tei:textLang" mode="m_tei-to-bibtex">
        <xsl:text>language = {</xsl:text>
            <xsl:value-of select="@mainLang"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
    </xsl:template> 
    
    <xsl:template match="tei:date" mode="m_tei-to-bibtex">
        <xsl:if test="string-length(@when)=10">
                <xsl:text>day = {</xsl:text>
                <xsl:value-of select="day-from-date(@when)"/>
                <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
                <xsl:text>month = {</xsl:text>
                <xsl:value-of select="month-from-date(@when)"/>
                <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
            </xsl:if>
            <!-- year-from-date works only with xs:date, which requires YYYY-MM-DD -->
            <xsl:text>year = {</xsl:text>
            <xsl:value-of select="substring(@when,1,4)"/>
            <xsl:text>}, </xsl:text><xsl:value-of select="$v_new-line"/>
    </xsl:template>
    
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_plain-text">
<!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
        <xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text> </xsl:text>
    </xsl:template>

    <!-- construct the head of the BibTeX file -->
    <xsl:template name="t_file-head">
        <!-- some metadata on the file itself -->
        <xsl:text>%% This BibTeX bibliography file was created by automatic conversion from TEI XML</xsl:text><xsl:value-of select="$v_new-line"/>
        <!--<xsl:text>%% Created at </xsl:text><xsl:value-of select="current-dateTime()"/><xsl:value-of select="$v_new-line"/>-->
        <xsl:text>%% Saved with string encoding Unicode (UTF-8) </xsl:text><xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_new-line"/>
    </xsl:template>
    
</xsl:stylesheet>