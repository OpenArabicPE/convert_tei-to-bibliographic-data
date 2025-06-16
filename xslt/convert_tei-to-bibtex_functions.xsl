<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="text" name="text" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <!-- this stylesheet translates <tei:biblStruct>s to  BibTeX -->
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
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
        <!-- input variables -->
        <xsl:variable name="v_biblStruct">
            <xsl:choose>
                <xsl:when test="$p_input/local-name() = 'bibl'">
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$p_input"/>
                </xsl:when>
                <xsl:when test="$p_input/local-name() = 'biblStruct'">
                    <xsl:apply-templates mode="m_copy-from-source" select="$p_input"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>Input is neither bibl nor biblStruct</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_analytic" select="$v_biblStruct/tei:biblStruct/tei:analytic"/>
        <xsl:variable name="v_monogr" select="$v_biblStruct/tei:biblStruct/tei:monogr"/>
        <xsl:variable name="v_imprint" select="$v_monogr/tei:imprint"/>
        <!-- output variables -->
        <xsl:variable name="v_bibtex-key" select="$p_input/tei:analytic/tei:idno[@type = 'BibTeX']"/>
        <!-- not sure this selects the correct date -->
        <xsl:variable name="v_publication-date">
            <xsl:choose>
                <!-- data on analytic -->
                <xsl:when test="$v_analytic/tei:date[string-length(@when) = 10]">
                    <xsl:copy-of select="$v_analytic/tei:date[string-length(@when) = 10][1]"/>
                </xsl:when>
                <!-- data on monograph -->
                <xsl:when test="$v_imprint/tei:date[string-length(@when) = 10]">
                    <xsl:copy-of select="$v_imprint/tei:date[string-length(@when) = 10][1]"/>
                </xsl:when>
                <xsl:when test="$v_imprint/tei:date[@when]">
                    <xsl:copy-of select="$v_imprint/tei:date[@when][1]"/>
                </xsl:when>
                <!-- some fallback -->
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_title-article">
            <xsl:choose>
                <xsl:when test="$v_analytic/tei:title[@level = 'a'][@xml:lang = $p_lang]">
                    <xsl:apply-templates mode="m_tei-to-bibtex" select="$v_analytic/tei:title[@level = 'a'][@xml:lang = $p_lang][1]"/>
                </xsl:when>
                <xsl:when test="$v_analytic/tei:title[@level = 'a']">
                    <xsl:apply-templates mode="m_tei-to-bibtex" select="$v_analytic/tei:title[@level = 'a'][1]"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_title-journal">
            <xsl:choose>
                <xsl:when test="$v_imprint/tei:title[@level = 'j'][@xml:lang = $p_lang][not(@type = 'sub')]">
                    <xsl:apply-templates mode="m_tei-to-bibtex" select="$v_imprint/tei:title[@level = 'j'][@xml:lang = $p_lang][not(@type = 'sub')][1]"/>
                </xsl:when>
                <xsl:when test="$v_imprint/tei:title[@level = 'j'][not(@type = 'sub')]">
                    <xsl:apply-templates mode="m_tei-to-bibtex" select="$v_imprint/tei:title[@level = 'j'][not(@type = 'sub')][1]"/>
                </xsl:when>
            </xsl:choose>
            <xsl:if test="$v_imprint/tei:title[@level = 'j'][@xml:lang = $p_lang][@type = 'sub']">
                <xsl:text>: </xsl:text>
                <xsl:value-of select="$v_imprint/tei:title[@level = 'j'][@xml:lang = $p_lang][@type = 'sub']"/>
            </xsl:if>
        </xsl:variable>
        <!-- construct BibText -->
        <xsl:text>@ARTICLE{</xsl:text>
        <!-- BibTextKey -->
        <xsl:value-of select="$v_bibtex-key"/>
        <xsl:text>, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <!-- author information -->
        <xsl:if test="$v_biblStruct/descendant::tei:author">
            <xsl:text>author = {</xsl:text>
            <xsl:for-each select="$v_biblStruct/descendant::tei:author">
                <xsl:choose>
                    <xsl:when test="tei:persName[@xml:lang = $p_lang]">
                        <xsl:apply-templates mode="m_tei-to-bibtex" select="tei:persName[@xml:lang = $p_lang][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_tei-to-bibtex" select="tei:persName[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="position() != last()">
                    <xsl:text> and </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>}, </xsl:text>
            <xsl:value-of select="$v_new-line"/>
        </xsl:if>
        <!-- editor information -->
        <xsl:if test="$v_biblStruct/descendant::tei:editor">
            <xsl:text>editor = {</xsl:text>
            <xsl:for-each select="$v_biblStruct/descendant::tei:editor">
                <xsl:choose>
                    <xsl:when test="tei:persName[@xml:lang = $p_lang]">
                        <xsl:apply-templates mode="m_tei-to-bibtex" select="tei:persName[@xml:lang = $p_lang][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_tei-to-bibtex" select="tei:persName[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="position() != last()">
                    <xsl:text> and </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>}, </xsl:text>
            <xsl:value-of select="$v_new-line"/>
        </xsl:if>
        <!-- titles -->
        <xsl:text>title = {</xsl:text>
        <xsl:value-of select="$v_title-article"/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>journal = {</xsl:text>
        <xsl:value-of select="$v_title-journal"/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <!-- imprint -->
        <xsl:apply-templates mode="m_tei-to-bibtex" select="$p_input/descendant::tei:biblScope"/>
        <xsl:apply-templates mode="m_tei-to-bibtex" select="$p_input/descendant::tei:publisher/node()[@xml:lang = $p_lang]"/>
        <xsl:text>address = {</xsl:text>
        <xsl:apply-templates mode="m_tei-to-bibtex" select="$p_input/descendant::tei:pubPlace/tei:placeName[@xml:lang = $p_lang]"/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <xsl:apply-templates mode="m_tei-to-bibtex" select="$p_input/descendant::tei:textLang"/>
        <!-- publication dates -->
        <xsl:apply-templates mode="m_tei-to-bibtex" select="$v_publication-date/tei:date"/>
        <!-- URL -->
        <xsl:text>url = {</xsl:text>
        <xsl:value-of select="$p_input/descendant::tei:idno[@type = 'url'][1]"/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <!-- add information on digital edition as a note -->
        <xsl:text>annote = {</xsl:text>
        <xsl:text>digital TEI edition, </xsl:text>
        <xsl:value-of select="year-from-date(current-date())"/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>}</xsl:text>
        <xsl:value-of select="$v_new-line"/>
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
    <xsl:template match="tei:persName" mode="m_tei-to-bibtex">
        <xsl:choose>
            <xsl:when test="tei:surname and tei:forename">
                <xsl:apply-templates mode="m_tei-to-bibtex" select="tei:surname"/>
                <xsl:text>, </xsl:text>
                <xsl:apply-templates mode="m_tei-to-bibtex" select="tei:forename"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_tei-to-bibtex" select="text()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_tei-to-bibtex">
        <xsl:value-of select="normalize-space(.)"/>
        <!--                <xsl:value-of select="replace(.,'[\s|\n]+',' ')"/>-->
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
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
    </xsl:template>
    <xsl:template match="tei:publisher/node()" mode="m_tei-to-bibtex">
        <xsl:text>publisher = {</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
    </xsl:template>
    <xsl:template match="tei:textLang" mode="m_tei-to-bibtex">
        <xsl:text>language = {</xsl:text>
        <xsl:value-of select="@mainLang"/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
    </xsl:template>
    <xsl:template match="tei:date" mode="m_tei-to-bibtex">
        <xsl:if test="string-length(@when) = 10">
            <xsl:text>day = {</xsl:text>
            <xsl:value-of select="day-from-date(@when)"/>
            <xsl:text>}, </xsl:text>
            <xsl:value-of select="$v_new-line"/>
            <xsl:text>month = {</xsl:text>
            <xsl:value-of select="month-from-date(@when)"/>
            <xsl:text>}, </xsl:text>
            <xsl:value-of select="$v_new-line"/>
        </xsl:if>
        <!-- year-from-date works only with xs:date, which requires YYYY-MM-DD -->
        <xsl:text>year = {</xsl:text>
        <xsl:value-of select="substring(@when, 1, 4)"/>
        <xsl:text>}, </xsl:text>
        <xsl:value-of select="$v_new-line"/>
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
        <xsl:text>%% This BibTeX bibliography file was created by automatic conversion from TEI XML</xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <!--<xsl:text>%% Created at </xsl:text><xsl:value-of select="current-dateTime()"/><xsl:value-of select="$v_new-line"/>-->
        <xsl:text>%% Saved with string encoding Unicode (UTF-8) </xsl:text>
        <xsl:value-of select="$v_new-line"/>
        <xsl:value-of select="$v_new-line"/>
    </xsl:template>
</xsl:stylesheet>
