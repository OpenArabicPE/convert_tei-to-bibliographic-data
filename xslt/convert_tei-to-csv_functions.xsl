<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="text" name="text" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>
    <!-- this stylesheet translates <tei:biblStruct>s to  csv -->
    <!-- toggle debugging messages -->
    <!-- this XSLT is already imported through chained XSLT -->
    <!--    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>-->
    <!-- import functions -->
    <!--    <xsl:include href="../../tools/xslt/openarabicpe_functions.xsl"/>-->
    <xsl:import href="../../authority-files/xslt/functions.xsl"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_quot" select="'&quot;'"/>
    <xsl:variable name="v_comma" select="','"/>
    <xsl:variable name="v_seperator" select="concat($v_quot, $v_comma, $v_quot)"/>
    <xsl:variable name="v_separator-attribute-key" select="'_'"/>
    <xsl:variable name="v_separator-attribute-value" select="'.'"/>
    <!-- select preference for output language -->
    <xsl:param name="p_output-language-persons" select="'ar'"/>
    <xsl:param name="p_output-language-places" select="'ar-Latn-x-ijmes'"/>
    <xsl:param name="p_output-language-titles" select="'ar-Latn-x-ijmes'"/>
    <!-- locate authority files -->
    <xsl:param name="p_path-authority-files" select="'../../authority-files/data/tei/'"/>
    <xsl:param name="p_file-name-gazetteer" select="'gazetteer_OpenArabicPE.TEIP5.xml'"/>
    <xsl:param name="p_file-name-personography" select="'personography_OpenArabicPE.TEIP5.xml'"/>
    <xsl:param name="p_file-name-bibliography"
        select="'bibliography_OpenArabicPE-periodicals.TEIP5.xml'"/>
    <!-- load the authority files -->
    <xsl:variable name="v_gazetteer"
        select="doc(concat($p_path-authority-files, $p_file-name-gazetteer))"/>
    <xsl:variable name="v_personography"
        select="doc(concat($p_path-authority-files, $p_file-name-personography))"/>
    <xsl:variable name="v_bibliography"
        select="doc(concat($p_path-authority-files, $p_file-name-bibliography))"/>
    <!--<xsl:variable name="vgFileId" select="substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5')"/>-->
    <xsl:variable name="v_csv-head">
        <!-- csv head -->
        <xsl:value-of select="$v_quot"/>
        <xsl:text>article.id</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>stylo.file.id</xsl:text><xsl:value-of select="$v_seperator"/>
        <!-- information of journal issue -->
        <xsl:text>publication.title</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>publication.id.oclc</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>date</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>volume</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>issue</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>publication.location.name</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>publication.location.id.oape</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>publication.location.coordinates</xsl:text><xsl:value-of select="$v_seperator"/>
        <!-- information on article -->
        <xsl:text>article.title</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>has.author</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>author.name</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>author.name.normalized</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>author.id.viaf</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>author.id.oape</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>author.birth</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>author.death</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>works.viaf.count</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>page.count</xsl:text><xsl:value-of select="$v_seperator"/>
        <xsl:text>word.count</xsl:text>
        <xsl:value-of select="$v_quot"/>
        <!--            <xsl:value-of select="$v_new-line"/>-->
    </xsl:variable>
    <!--<xsl:template match="tei:biblStruct">
        <xsl:value-of select="oape:bibliography-tei-to-csv(.,'ar')"/>
    </xsl:template>-->
    <xsl:function name="oape:bibliography-tei-to-csv">
        <!-- input is a bibl or biblStruct -->
        <xsl:param as="node()" name="p_input"/>
        <!-- output language -->
        <!--        <xsl:param name="p_lang"/>-->
        <!-- missing bits: absent from biblStruct
            - licence
            - date last accessed
            - edition
        -->
        <xsl:variable name="v_id-file"
            select="$p_input/tei:monogr/tei:idno[@type = 'URI'][matches(., '^oclc_')][1]"/>
        <xsl:variable name="v_id-div"
            select="substring-after($p_input/tei:analytic/tei:idno[@type = 'url'][contains(., 'xml#')][1], '#')"/>
        <xsl:variable name="v_id-publication"
            select="$p_input/descendant::tei:idno[@type = 'OCLC'][1]"/>
        <xsl:variable name="v_title-publication"
            select="oape:query-bibliography($p_input/tei:monogr/tei:title[1], $v_bibliography, '', '', 'name', $p_output-language-titles)"/>
        <xsl:variable name="v_publication-place"
            select="$p_input/tei:monogr/tei:imprint/tei:pubPlace[1]/tei:placeName[1]"/>
        <xsl:variable name="v_title-article" select="$p_input/tei:analytic/tei:title[1]"/>
        <xsl:variable name="v_author">
            <xsl:choose>
                <xsl:when test="$p_input/tei:analytic/tei:author">
                    <xsl:copy-of select="$p_input/tei:analytic/tei:author"/>
                </xsl:when>
                <xsl:when test="$p_input/tei:monogr/tei:author">
                    <xsl:copy-of select="$p_input/tei:monogr/tei:author"/>
                </xsl:when>
                <!-- fallback -->
                <xsl:otherwise>
                    <xsl:text>NA</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- pull author from authority file -->
        <xsl:variable name="v_author-entity" select="oape:get-entity-from-authority-file($v_author/descendant-or-self::tei:persName[1], $p_local-authority, $v_personography)"/>
        <xsl:variable name="v_id-author-oape"
            select="oape:query-person($v_author-entity, 'id-local', '', $p_local-authority)"/>
        <xsl:variable name="v_volume">
            <xsl:apply-templates mode="m_tei-to-csv"
                select="$p_input/tei:monogr/tei:biblScope[@unit = 'volume']"/>
        </xsl:variable>
        <xsl:variable name="v_issue">
            <xsl:apply-templates mode="m_tei-to-csv"
                select="$p_input/tei:monogr/tei:biblScope[@unit = 'issue']"/>
        </xsl:variable>
        <xsl:variable name="v_page-count">
            <xsl:choose>
                <xsl:when
                    test="$p_input//tei:biblScope[@unit = 'page']/@from = $p_input//tei:biblScope[@unit = 'page']/@to">
                    <xsl:value-of select="1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="$p_input//tei:biblScope[@unit = 'page']/@to - $p_input//tei:biblScope[@unit = 'page']/@from + 1"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_date"
            select="$p_input/tei:monogr/tei:imprint/tei:date[@when][1]/@when"/>
        <xsl:variable name="v_id-stylo">
            <xsl:choose>
                <xsl:when test="$v_id-author-oape != 'NA'">
                    <xsl:value-of select="concat('oape', $v_separator-attribute-value)"/>
                    <xsl:value-of select="oape:query-person($v_author-entity, 'id-local', '', $p_local-authority)"/>
                </xsl:when>
               <!-- <xsl:when test="$v_author/descendant-or-self::tei:persName/@ref">
                    <xsl:value-of select="concat('oape', $v_separator-attribute-value)"/>
                    <xsl:value-of
                        select="oape:query-personography($v_author/descendant-or-self::tei:persName[1], $v_personography, $p_local-authority, 'id-local', '')"
                    />
                </xsl:when>-->
                <xsl:when test="$v_author/descendant::tei:surname">
                    <xsl:value-of select="$v_author/descendant::tei:surname"/>
                </xsl:when>
                <xsl:when test="$v_author/descendant::tei:persName">
                    <xsl:value-of select="$v_author/descendant::tei:persName"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>NN</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of
                select="concat($v_separator-attribute-key, 'oclc', $v_separator-attribute-value, $v_id-publication, $v_separator-attribute-key, 'v', $v_separator-attribute-value, translate($v_volume, '/', '-'), $v_separator-attribute-key, 'i', $v_separator-attribute-value, $v_issue, $v_separator-attribute-key, $v_id-div)"
            />
        </xsl:variable>
        <xsl:variable name="v_text">
            <xsl:apply-templates select="doc($v_url-file)/descendant::node()[@xml:id = $v_id-div]" mode="m_identity-transform"/>
        </xsl:variable>
        <xsl:variable name="v_word-count" select="number(count(tokenize(string($v_text), '\W+')))"/>
        <!-- output -->
        <!-- article ID -->
        <xsl:value-of select="$v_quot"/>
        <xsl:value-of select="concat($v_id-file, '-', $v_id-div)"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- stylo file name / ID -->
        <xsl:value-of select="$v_id-stylo"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- publication title -->
        <xsl:value-of select="$v_title-publication"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- publication ID: OCLC -->
        <xsl:value-of select="$v_id-publication"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- date -->
        <xsl:value-of select="$v_date"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- volume -->
        <xsl:value-of select="$v_volume"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- issue -->
        <xsl:value-of select="$v_issue"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- publication place -->
        <xsl:value-of
            select="oape:query-gazetteer($v_publication-place, $v_gazetteer, '', 'name', $p_output-language-places)"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:value-of
            select="oape:query-gazetteer($v_publication-place, $v_gazetteer, $p_local-authority, 'id-local', '')"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:value-of
            select="oape:query-gazetteer($v_publication-place, $v_gazetteer, '', 'location', '')"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- article title -->
        <xsl:value-of select="$v_title-article"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- has author? -->
        <xsl:choose>
            <xsl:when test="$v_author != 'NA'">
                <xsl:text>T</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>F</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$v_seperator"/>
        <!-- author names -->
        <!--<xsl:for-each select="$v_author/descendant-or-self::tei:persName">
            <xsl:apply-templates mode="m_plain-text" select="."/>
            <xsl:if test="position() != last()">
                <xsl:text>|</xsl:text>
            </xsl:if>
        </xsl:for-each>-->
        <xsl:apply-templates select="$v_author/descendant-or-self::tei:persName[1]" mode="m_plain-text"/><xsl:value-of select="$v_seperator"/>
        <!-- normalized -->
        <!--<xsl:for-each select="$v_author/descendant-or-self::tei:persName">
            <xsl:value-of
                select="oape:query-personography(., $v_personography, '', 'name', $p_output-language-persons)"/>
            <xsl:if test="position() != last()">
                <xsl:text>|</xsl:text>
            </xsl:if>
        </xsl:for-each>-->
        <xsl:value-of select="oape:query-person($v_author-entity, 'name', $p_output-language-persons, $p_local-authority)"/><xsl:value-of select="$v_seperator"/>
        <!-- author id: VIAF -->
        <xsl:value-of select="oape:query-person($v_author-entity, 'id-viaf', '', $p_local-authority)"/><xsl:value-of select="$v_seperator"/>
        <!-- author id: OpenArabicPE (local authority file) -->
        <xsl:value-of select="$v_id-author-oape"/><xsl:value-of select="$v_seperator"/>
        <!-- birth -->
        <xsl:value-of select="oape:query-person($v_author-entity, 'date-birth', '', $p_local-authority)"/><xsl:value-of select="$v_seperator"/>
        <!-- death -->
        <xsl:value-of select="oape:query-person($v_author-entity, 'date-death', '', $p_local-authority)"/><xsl:value-of select="$v_seperator"/>
        <!-- number of works in VIAF -->
        <xsl:value-of select="oape:query-person($v_author-entity, 'countWorks', '', $p_local-authority)"/><xsl:value-of select="$v_seperator"/>
        <!-- number of pages -->
        <xsl:value-of select="$v_page-count"/><xsl:value-of select="$v_seperator"/>
        <!-- number of words -->
        <xsl:value-of select="$v_word-count"/>
        <!-- end of line -->
        <xsl:value-of select="$v_quot"/>
        <!--                <xsl:value-of select="$v_new-line"/>-->
    </xsl:function>
    <xsl:template match="tei:lb | tei:cb | tei:pb" mode="m_tei-to-csv">
        <xsl:text> </xsl:text>
    </xsl:template>
    <!-- prevent notes in div/head from producing output -->
    <xsl:template match="tei:head/tei:note" mode="m_tei-to-csv"/>
    <xsl:template match="tei:head" mode="m_tei-to-csv">
        <xsl:apply-templates mode="m_tei-to-csv"/>
    </xsl:template>
    <!-- authors -->
    <xsl:template match="tei:persName" mode="m_tei-to-csv">
        <xsl:choose>
            <xsl:when test="tei:surname and tei:forename">
                <xsl:apply-templates mode="m_tei-to-csv" select="tei:surname"/>
                <xsl:text>, </xsl:text>
                <xsl:apply-templates mode="m_tei-to-csv" select="tei:forename"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_tei-to-csv">
        <xsl:value-of select="replace(., '[\s|\n]+', ' ')"/>
    </xsl:template>
    <xsl:template match="tei:biblScope" mode="m_tei-to-csv">
        <xsl:choose>
            <xsl:when test="@from = @to">
                <xsl:value-of select="@from"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(@from, '-', @to)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_plain-text">
        <!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
        <xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text> </xsl:text>
    </xsl:template>
</xsl:stylesheet>
