<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:cc="http://web.resource.org/cc/" xmlns:dhq="http://www.digitalhumanities.org/ns/dhq"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" name="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:import href="functions.xsl"/>
    <!-- which functions do I actually need? -->
    <!--    <xsl:import href="../../authority-files/xslt/functions.xsl"/>-->
    <!-- are translators covered? -->
    <!-- problems
        - multiple surnames: e.g. Saʿīd al-Khūrī al-Shartūnī
    -->
    <!--    <xsl:param name="p_include-section-titles" select="true()"/>-->
    <!-- this stylesheets takes a <tei:div> as input and generates a <biblStruct> -->
    <xsl:function name="oape:bibliography-tei-div-to-biblstruct">
        <xsl:param name="p_div"/>
        <!--        <xsl:param name="p_translate-url-github-to-gh-pages"/>-->
        <xsl:variable name="v_source-monogr" select="$p_div/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[1]/tei:monogr"/>
        <xsl:variable name="v_id-file">
            <xsl:choose>
                <xsl:when test="$p_div/ancestor::tei:TEI/@xml:id">
                    <xsl:value-of select="$p_div/ancestor::tei:TEI/@xml:id"/>
                </xsl:when>
                <!-- fallback: OCLC -->
                <xsl:when test="$v_source-monogr/tei:idno[@type = 'OCLC']">
                    <xsl:value-of select="concat('oclc_', $v_source-monogr/tei:idno[@type = 'OCLC'][1])"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_id-div" select="$p_div/@xml:id"/>
        <xsl:variable name="v_bibtex-key" select="concat($v_id-file, '-', $v_id-div)"/>
        <xsl:element name="biblStruct">
            <xsl:element name="analytic">
                <!-- article title -->
                <xsl:element name="title">
                    <xsl:attribute name="level" select="'a'"/>
                    <xsl:attribute name="xml:lang" select="$p_div/@xml:lang"/>
                    <!-- with a single head, this function still returns two strings (the second is empty) -->
                    <xsl:value-of select="
                            oape:get-title-from-div($p_div, if ($v_source-monogr/tei:title/@level = 'm') then
                                (false())
                            else
                                (true()))"/>
                </xsl:element>
                <!-- authorship  information -->
                <!-- if the input is not a periodical but a book, the book's author should be replicated here -->
                <xsl:choose>
                    <xsl:when test="$v_source-monogr/tei:title/@level = 'm'">
                        <xsl:apply-templates mode="m_replicate" select="$v_source-monogr/descendant::tei:author"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="author">
                            <xsl:apply-templates mode="m_replicate" select="oape:get-author-from-div($p_div)"/>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- further responsibilities -->
                <xsl:choose>
                    <xsl:when test="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:respStmt">
                        <xsl:copy-of select="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:respStmt"/>
                    </xsl:when>
                </xsl:choose>
                <!-- IDs: URL -->
                <xsl:for-each select="$p_div/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type = 'url']">
                    <xsl:element name="idno">
                        <xsl:attribute name="type" select="'url'"/>
                        <xsl:value-of select="concat(., '#', $v_id-div)"/>
                    </xsl:element>
                </xsl:for-each>
                <!-- add gh-pages -->
                <xsl:if test="not($p_div/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type = 'url'][contains(., '.github.io/')])">
                    <xsl:element name="idno">
                        <xsl:attribute name="type" select="'url'"/>
                        <xsl:value-of
                            select="concat(oape:transform-url-github-gh-pages($p_div/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type = 'url'][not(contains(., '.github.io/'))]), '#', $v_id-div)"
                        />
                    </xsl:element>
                </xsl:if>
                <!-- BibTeX key -->
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'BibTeX'"/>
                    <xsl:value-of select="$v_bibtex-key"/>
                </xsl:element>
            </xsl:element>
            <!-- copy information from the file's sourceDesc -->
            <xsl:element name="monogr">
                <!-- title -->
                <xsl:apply-templates mode="m_replicate" select="$v_source-monogr/tei:title"/>
                <!-- IDs -->
                <xsl:apply-templates mode="m_replicate" select="$v_source-monogr/tei:idno"/>
                <!-- add file name as ID -->
                <xsl:element name="tei:idno">
                    <xsl:attribute name="type" select="'URI'"/>
                    <xsl:value-of select="$v_id-file"/>
                </xsl:element>
                <!-- text languages -->
                <xsl:choose>
                    <xsl:when test="$v_source-monogr/tei:textLang">
                        <xsl:apply-templates mode="m_replicate" select="$v_source-monogr/tei:textLang"/>
                    </xsl:when>
                    <xsl:when test="$p_div/@xml:lang">
                        <xsl:element name="tei:textLang">
                            <xsl:attribute name="mainLang" select="$p_div/@xml:lang"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
                <!-- editor -->
                <xsl:apply-templates mode="m_replicate" select="$v_source-monogr/tei:editor"/>
                <!-- imprint -->
                <xsl:apply-templates mode="m_replicate" select="$v_source-monogr/tei:imprint"/>
                <!-- volume and issue -->
                <xsl:apply-templates mode="m_replicate" select="$v_source-monogr/tei:biblScope[not(@unit = 'page')]"/>
                <!-- page numbers -->
                <xsl:element name="biblScope">
                    <xsl:attribute name="unit" select="'page'"/>
                    <xsl:variable name="v_page-onset" select="$p_div/preceding::tei:pb[@ed = 'print'][1]/@n"/>
                    <xsl:variable name="v_page_terminus">
                        <xsl:choose>
                            <xsl:when test="$p_div/descendant::tei:pb[@ed = 'print']">
                                <xsl:value-of select="$p_div/descendant::tei:pb[@ed = 'print'][last()]/@n"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$v_page-onset"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:attribute name="from" select="$v_page-onset"/>
                    <xsl:attribute name="to" select="$v_page_terminus"/>
                    <xsl:value-of select="concat($v_page-onset, '-', $v_page_terminus)"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:function>
    <!-- function to get the author(s) of a div -->
    <xsl:function name="oape:get-author-from-div">
        <xsl:param name="p_div"/>
        <xsl:choose>
            <xsl:when test="$p_div/child::tei:byline/descendant::tei:persName[not(ancestor::tei:note)]">
                <xsl:copy-of select="$p_div/child::tei:byline/descendant::tei:persName[not(ancestor::tei:note)]"/>
            </xsl:when>
            <xsl:when test="$p_div/child::tei:byline/descendant::tei:orgName[not(ancestor::tei:note)]">
                <xsl:copy-of select="$p_div/child::tei:byline/descendant::tei:orgName[not(ancestor::tei:note)]"/>
            </xsl:when>
            <!-- there is a problem here: sections will inherit all the authors of the contained items -->
            <xsl:when test="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:author">
                <xsl:copy-of select="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:author/descendant::tei:persName"/>
            </xsl:when>
            <xsl:when test="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:title[@level = 'j']">
                <xsl:copy-of select="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:title[@level = 'j']"/>
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:text>NA</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- function to get a title of a div -->
    <xsl:function name="oape:get-title-from-div">
        <xsl:param name="p_div"/>
        <xsl:param name="p_include-section-titles"/>
        <!-- include section titles -->
        <xsl:if test="$p_include-section-titles = true()">
            <xsl:if test="$p_div/@type = 'item' and $p_div/ancestor::tei:div[@type = 'section']">
                <xsl:apply-templates mode="m_tei-to-biblstruct" select="$p_div/ancestor::tei:div[@type = 'section']/tei:head"/>
                <xsl:text>: </xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:apply-templates mode="m_tei-to-biblstruct" select="$p_div/tei:head"/>
    </xsl:function>
    <!-- this removes notes from heads -->
    <xsl:template match="tei:head" mode="m_tei-to-biblstruct">
        <xsl:apply-templates mode="m_tei-to-biblstruct"/>
    </xsl:template>
    <xsl:template match="tei:head/tei:note" mode="m_tei-to-biblstruct" priority="10"/>
    <!-- text that contains non-whitespace characters -->
    <xsl:template match="text()[normalize-space(.)]" mode="m_tei-to-biblstruct">
        <!--        <xsl:if test="position() &gt; 1">-->
        <xsl:text> </xsl:text>
        <!--</xsl:if>-->
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <!-- function to convert GitHub URLs to gh-pages  -->
    <!-- input / output: string -->
    <xsl:function name="oape:transform-url-github-gh-pages">
        <xsl:param name="p_url"/>
        <xsl:analyze-string regex="https*://github\.com/(\w+)/(.+?)/blob/master/(.+\.xml)" select="$p_url">
            <xsl:matching-substring>
                <xsl:value-of select="concat('https://', regex-group(1), '.github.io/', regex-group(2), '/', regex-group(3))"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    <xsl:template match="node()" mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates mode="m_replicate" select="@*"/>
            <!-- add missing language information -->
            <xsl:if test="not(@xml:lang) and ancestor::node()[@xml:lang != ''][1]/@xml:lang">
                <xsl:attribute name="xml:lang" select="ancestor::node()[@xml:lang != ''][1]/@xml:lang"/>
            </xsl:if>
            <xsl:apply-templates mode="m_replicate" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_replicate"/>
    <!-- in some cases the content has been wrapped in <del>. Such content should be o -->
    <xsl:template match="tei:del" mode="m_bibl-to-biblStruct"/>
    <xsl:template match="tei:bibl" mode="m_bibl-to-biblStruct">
        <xsl:variable name="v_source">
            <xsl:choose>
                <xsl:when test="@source">
                    <!-- base-uri() is relative to the current context. if the <bibl> was generated by XSLT, this will be the context -->
                    <!--                    <xsl:value-of select="concat(@source, ' ', base-uri(), '#', @xml:id)"/>-->
                    <xsl:value-of select="concat(@source, ' ', $v_path-source, '#', @xml:id)"/>
                </xsl:when>
                <xsl:otherwise>
                    <!--                    <xsl:value-of select="concat(base-uri(), '#', @xml:id)"/>-->
                    <xsl:value-of select="concat($v_path-source, '#', @xml:id)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- publication date of the source file -->
        <xsl:variable name="v_source-date" select="document($v_url-file)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/descendant::tei:biblStruct[1]/descendant::tei:date[@when][1]/@when"/>
        <biblStruct>
            <xsl:apply-templates mode="m_bibl-to-biblStruct" select="@*"/>
            <!-- document source of information -->
            <xsl:attribute name="source" select="$v_source"/>
            <!--<xsl:attribute name="change" select="concat('#', $p_id-change)"/>-->
            <xsl:if test="tei:title[@level = 'a']">
                <analytic>
                    <xsl:apply-templates mode="m_replicate" select="tei:title[@level = 'a']"/>
                    <xsl:apply-templates mode="m_replicate" select="tei:author"/>
                </analytic>
            </xsl:if>
            <monogr>
                <xsl:apply-templates mode="m_replicate" select="tei:title[@level != 'a']"/>
                <xsl:apply-templates mode="m_replicate" select="tei:title[not(@level)]"/>
                <xsl:apply-templates mode="m_replicate" select="tei:idno"/>
                <xsl:for-each select="tokenize(tei:title[(@level != 'a') or not(@level)][@ref][1]/@ref, '\s+')">
                    <xsl:variable name="v_authority">
                        <xsl:choose>
                            <xsl:when test="contains(., 'wiki:')">
                                <xsl:text>wiki</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(., 'oclc:')">
                                <xsl:text>OCLC</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(., 'jaraid:')">
                                <xsl:text>jaraid</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(., 'oape:')">
                                <xsl:text>oape</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="v_local-uri-scheme" select="concat($v_authority, ':bibl:')"/>
                    <xsl:variable name="v_idno">
                        <xsl:choose>
                            <xsl:when test="contains(., $v_local-uri-scheme)">
                                <!-- local IDs in Project Jaraid are not nummeric for biblStructs -->
                                <xsl:value-of select="replace(., concat('.*', $v_local-uri-scheme, '(\w+).*'), '$1')"/>
                            </xsl:when>
                            <xsl:when test="matches(., concat($v_authority, ':'), 'i')">
                                <xsl:value-of select="replace(., concat($v_authority, ':'), '', 'i')"/>
                                <!--                                <xsl:value-of select="replace(., '.*oclc:(\d+).*', '$1')"/>-->
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:if test="$v_idno != ''">
                        <idno type="{$v_authority}">
                            <xsl:value-of select="$v_idno"/>
                        </idno>
                    </xsl:if>
                </xsl:for-each>
                <xsl:choose>
                    <xsl:when test="tei:textLang">
                        <xsl:apply-templates mode="m_replicate" select="tei:textLang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="v_lang">
                            <xsl:choose>
                                <!-- chose the language of the title -->
                                <xsl:when test="tei:title[@level != 'a']/@xml:lang">
                                    <xsl:value-of select="tei:title[@level != 'a'][@xml:lang][1]/@xml:lang"/>
                                </xsl:when>
                                <xsl:when test="tei:title[@level != 'm']/@xml:lang">
                                    <xsl:value-of select="tei:title[@level != 'm'][@xml:lang][1]/@xml:lang"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>There is no language information for this bibl</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:value-of select="'NA'"/>
                                    <!--                                        <xsl:value-of select="$p_target-language"/>-->
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:if test="$v_lang != 'NA'">
                            <textLang>
                                <xsl:attribute name="mainLang" select="$v_lang"/>
                            </textLang>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- author: depending on which level we are on -->
                <xsl:choose>
                    <!-- if this is for a book section, article etc., the author has been part of <analytic> -->
                    <xsl:when test="tei:title[@level = 'a']"/>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_bibl-to-biblStruct" select="tei:author"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates mode="m_bibl-to-biblStruct" select="tei:editor"/>
                <imprint>
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:date"/>
                    <!-- add a date at which this bibl was documented in the source file -->
                    <xsl:if test="$v_source-date != ''">
                        <date source="{$v_source}" type="documented" when="{$v_source-date}"/>
                    </xsl:if>
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="tei:pubPlace"/>
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="tei:publisher"/>
                </imprint>
                <xsl:apply-templates mode="m_replicate" select="tei:biblScope"/>
            </monogr>
            <!-- retain all potential notes  -->
            <xsl:apply-templates mode="m_replicate" select="tei:note"/>
        </biblStruct>
    </xsl:template>
    <xsl:template match="node() | @*" mode="m_bibl-to-biblStruct">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_bibl-to-biblStruct"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:author[tei:persName]/@xml:lang  | tei:bibl/@xml:lang | tei:editor[tei:persName]/@xml:lang  | tei:monogr/@xml:lang| tei:pubPlace[tei:placeName]/@xml:lang" mode="m_bibl-to-biblStruct"/>
    <!-- produce simple derivates of tei:biblStruct -->
    <xsl:template match="tei:biblStruct" mode="m_simple">
        <xsl:copy>
            <!-- select attributes -->
            <xsl:apply-templates mode="m_simple" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- excluded attributes  -->
    <xsl:template
        match="@change | @resp | @xml:id | @xml:lang[parent::tei:biblScope | parent::tei:biblStruct | parent::tei:date | parent::tei:editor | parent::tei:publisher | parent::tei:pubPlace] | @source[parent::tei:idno | parent::tei:monogr | parent::tei:orgName | parent::tei:persName] | tei:editor/@ref | tei:persName/@type"
        mode="m_simple"/>
    <!-- excluded nodes: all notes, including holdings -->
    <xsl:template match="tei:biblStruct/tei:note | tei:monogr/tei:respStmt" mode="m_simple"/>
    <xsl:template match="tei:date" mode="m_simple">
        <!-- select only the earliest onset, and the latest terminus -->
        <xsl:copy>
            <xsl:choose>
                <!-- reduce nodes to machine readability -->
                <xsl:when test="@when | @notBefore | @notAfter">
                    <xsl:apply-templates mode="m_simple" select="@*"/>
                </xsl:when>
                <xsl:when test="matches(., '^\d{4}-\d{2}-\d{2}')">
                    <xsl:attribute name="when" select="replace(., '^(\d{4}-\d{2}-\d{2}).*$', '$1')"/>
                    <xsl:apply-templates mode="m_simple"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="m_simple" select="@* | node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@when[parent::tei:date/@cert = 'low'][xs:date(.)]" mode="m_simple">
        <xsl:attribute name="when">
            <xsl:value-of select="year-from-date(.)"/>
        </xsl:attribute>
    </xsl:template>
    <!--<xsl:template match="tei:date/@cert" mode="m_simple"/>-->
    <xsl:template match="tei:biblScope" mode="m_simple">
        <xsl:copy>
            <xsl:choose>
                <!-- normalise funky attribute values -->
                <xsl:when test="@unit != ('chapter', 'column', 'issue', 'line', 'page', 'part', 'volume')">
                    <xsl:message>
                        <xsl:text>The value of @unit (</xsl:text>
                        <xsl:value-of select="@unit"/>
                        <xsl:text>) is not part of the canonical list</xsl:text>
                    </xsl:message>
                    <!-- this is ZfDG -->
                    <xsl:if test="@unit = 'year'">
                        <xsl:attribute name="unit" select="'volume'"/>
                        <xsl:apply-templates mode="m_simple" select="node()"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="@unit and @from and @to">
                    <xsl:apply-templates mode="m_simple" select="@*"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="m_simple" select="@* | node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!-- reduce children -->
    <xsl:template match="tei:monogr" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates mode="m_simple" select="@*"/>
            <!-- reproduce all known titles -->
            <xsl:apply-templates mode="m_simple" select="tei:title"/>
            <xsl:apply-templates mode="m_simple" select="tei:idno">
                <xsl:sort select="@type"/>
                <xsl:sort data-type="number" select="replace(., '[^\d]', '')"/>
            </xsl:apply-templates>
            <xsl:apply-templates mode="m_simple" select="tei:textLang"/>
            <xsl:apply-templates mode="m_simple" select="tei:editor"/>
            <xsl:apply-templates mode="m_simple" select="tei:imprint"/>
            <xsl:apply-templates mode="m_simple" select="descendant::tei:biblScope"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:imprint" mode="m_simple">
        <xsl:copy>
            <!-- date -->
            <!-- exclude all dates that originated from library catalogues -->
            <xsl:variable name="v_dates">
                <xsl:for-each select="tei:date">
                    <xsl:choose>
                        <xsl:when test="matches(@source, '^(oape:org:\d+\s*)+$')">
                            <xsl:if test="$p_verbose">
                                <xsl:message>
                                    <xsl:text>date has been removed as it was sourced from a library catalogue and likely faulty</xsl:text>
                                </xsl:message>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_identity-transform" select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>
            <!-- onset -->
            <!--            <xsl:apply-templates mode="m_simple" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'date-onset', '', '', '')"/>-->
            <xsl:variable name="v_onset">
                <xsl:for-each select="$v_dates/descendant-or-self::tei:date[@type = 'onset']">
                    <!--                <xsl:for-each select="tei:date[not(@type = ('documented', 'terminus'))]">-->
                    <xsl:variable name="v_date" select="oape:date-get-onset(.)"/>
                    <xsl:copy>
                        <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                        <!-- test for year only, which is not an ISO date -->
                        <xsl:choose>
                            <xsl:when test="matches($v_date, '^\d{4}$')">
                                <xsl:value-of select="concat($v_date, '-01-01')"/>
                            </xsl:when>
                            <xsl:when test="matches($v_date, '^\d{4}-\d{2}-\d{2}$')">
                                <xsl:value-of select="$v_date"/>
                            </xsl:when>
                            <!-- set fallback: ISO date that will not be selected as onset -->
                            <xsl:otherwise>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:variable>
            <xsl:apply-templates mode="m_simple" select="$v_onset/descendant-or-self::tei:date[. != 'NA'][. = min(xs:date(.))][1]"/>
            <!-- documented -->
            <xsl:choose>
                <xsl:when test="$v_dates/descendant-or-self::tei:date[@when | @notAfter | @notBefore]/@type = 'documented'">
                    <xsl:apply-templates mode="m_simple" select="$v_dates/descendant-or-self::tei:date[@when | @notAfter | @notBefore][@type = 'documented']"/>
                </xsl:when>
                <xsl:when test="$v_dates/descendant-or-self::tei:date[@type = 'documented']">
                    <xsl:apply-templates mode="m_simple" select="$v_dates/descendant-or-self::tei:date[@type = 'documented']"/>
                </xsl:when>
            </xsl:choose>
            <!-- terminus  -->
            <!--            <xsl:apply-templates mode="m_simple" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'date-terminus', '', '', '')"/>-->
            <xsl:variable name="v_terminus">
                <xsl:for-each select="$v_dates/descendant-or-self::tei:date[@type = 'terminus']">
                    <!--                <xsl:for-each select="tei:date[not(@type = ('documented', 'onset'))]">-->
                    <xsl:variable name="v_date" select="oape:date-get-terminus(.)"/>
                    <xsl:copy>
                        <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                        <!-- test for year only, which is not an ISO date -->
                        <xsl:choose>
                            <xsl:when test="matches($v_date, '^\d{4}$')">
                                <xsl:value-of select="concat($v_date, '-12-31')"/>
                            </xsl:when>
                            <xsl:when test="matches($v_date, '^\d{4}-\d{2}-\d{2}$')">
                                <xsl:value-of select="$v_date"/>
                            </xsl:when>
                            <!-- set fallback: ISO date that will not be selected as terminus -->
                            <xsl:otherwise>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:variable>
            <xsl:apply-templates mode="m_simple" select="$v_terminus/descendant-or-self::tei:date[. != 'NA'][. = max(xs:date(.))][1]"/>
            <xsl:if test="not($v_dates/descendant-or-self::tei:date[@type])">
                <xsl:apply-templates mode="m_simple" select="$v_dates/descendant-or-self::tei:date[1]"/>
            </xsl:if>
            <!-- select only the first publisher and location -->
            <xsl:apply-templates mode="m_simple" select="tei:pubPlace[1] | tei:publisher[1]"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:surname | tei:forename" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates mode="m_simple" select="@*"/>
            <xsl:variable name="v_plain-text">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain-text)"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:textLang" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates mode="m_simple" select="@mainLang"/>
            <xsl:apply-templates mode="m_simple" select="@source"/>
        </xsl:copy>
        <xsl:if test="@otherLangs">
            <xsl:variable name="v_source" select="@source"/>
            <xsl:for-each select="tokenize(@otherLangs, '\s')">
                <xsl:element name="textLang">
                    <xsl:attribute name="mainLang" select="."/>
                    <xsl:if test="$v_source != ''">
                        <xsl:attribute name="source" select="$v_source"/>
                    </xsl:if>
                </xsl:element>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <!-- replicate everything that has not been excluded -->
    <xsl:template match="node()" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates mode="m_simple" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@*" mode="m_simple m_replicate">
        <xsl:if test="string-length(.) != 0">
            <xsl:copy/>
        </xsl:if>
    </xsl:template>
    <!-- conversion of information from fileDesc -->
    <xsl:template match="tei:fileDesc" mode="m_fileDesc-to-biblStruct">
        <xsl:choose>
            <xsl:when test="tei:publicationStmt[descendant::tei:biblStruct]">
                <biblStruct>
                    <xsl:apply-templates mode="m_identity-transform" select="tei:publicationStmt/descendant::tei:biblStruct/node()"/>
                    <!-- add keywords from profileDesc -->
                    <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="following-sibling::tei:profileDesc/tei:textClass"/>
                </biblStruct>
            </xsl:when>
            <xsl:when test="tei:publicationStmt[descendant::tei:bibl]"/>
            <!-- this is the weird encoding used by ZfDG -->
            <xsl:when test="tei:titleStmt/tei:title/tei:biblStruct">
                <biblStruct>
                    <xsl:apply-templates mode="m_simple" select="tei:titleStmt/tei:title/tei:biblStruct/node()"/>
                    <!-- add keywords from profileDesc -->
                    <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="following-sibling::tei:profileDesc/tei:textClass"/>
                </biblStruct>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="v_publicationStmt" select="tei:publicationStmt"/>
                <xsl:variable name="v_titleStmt" select="tei:titleStmt"/>
                <xsl:variable name="v_editionStmt" select="tei:editionStmt"/>
                <biblStruct>
                    <analytic>
                        <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="$v_titleStmt/tei:title"/>
                        <xsl:choose>
                            <!-- dealing with DHQ files -->
                            <xsl:when test="$v_titleStmt/descendant::dhq:authorInfo">
                                <xsl:apply-templates mode="m_dhq-to-biblStruct" select="$v_titleStmt/descendant::dhq:authorInfo"/>
                            </xsl:when>
                            <!-- normal TEI markup -->
                            <xsl:when test="$v_titleStmt/tei:author">
                                <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="$v_titleStmt/tei:author"/>
                            </xsl:when>
                        </xsl:choose>
                        <!-- language -->
                        <textLang mainLang="{following-sibling::tei:profileDesc/tei:langUsage/tei:language/@ident}"/>
                        <!-- IDs -->
                        <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="$v_publicationStmt/tei:idno[@type = ('DHQarticle-id')]"/>
                        <!-- date -->
                        <xsl:apply-templates mode="m_simple" select="$v_editionStmt/tei:edition/tei:date"/>
                        <!-- availability -->
                        <xsl:apply-templates mode="m_identity-transform" select="$v_publicationStmt/tei:availability"/>
                    </analytic>
                    <monogr>
                        <!-- add missing journal title for DHQ -->
                        <xsl:if test="$v_publicationStmt/tei:idno[@type = 'DHQarticle-id']">
                            <title level="j" xml:lang="en">Digital Humanities Quarterly</title>
                        </xsl:if>
                        <imprint>
                            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="$v_publicationStmt/tei:publisher"/>
                            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="$v_publicationStmt/tei:date"/>
                        </imprint>
                        <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="$v_publicationStmt/tei:idno[@type = ('volume', 'issue')]"/>
                    </monogr>
                    <!-- add keywords from profileDesc -->
                    <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="following-sibling::tei:profileDesc/tei:textClass"/>
                </biblStruct>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:textClass" mode="m_fileDesc-to-biblStruct">
        <note type="tagList">
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="tei:keywords"/>
        </note>
    </xsl:template>
    <xsl:template match="tei:keywords" mode="m_fileDesc-to-biblStruct">
        <list>
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="@scheme | @n"/>
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="tei:term"/>
        </list>
    </xsl:template>
    <xsl:template match="tei:term" mode="m_fileDesc-to-biblStruct">
        <item>
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="parent::tei:keywords/@scheme"/>
            <!--<xsl:if test="parent::tei:keywords/@n">
                <xsl:copy-of select="parent::tei:keywords/@n"/>
            </xsl:if>
            <xsl:if test="parent::tei:keywords/@scheme">
                <xsl:attribute name="source">
                    <xsl:value-of select="normalize-space(parent::tei:keywords/@scheme)"/>
                </xsl:attribute>
            </xsl:if>-->
            <label>
                <xsl:value-of select="normalize-space(.)"/>
            </label>
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct"/>
        </item>
    </xsl:template>
    <!-- this is specifically for ZfDG -->
    <xsl:template match="tei:keywords[@scheme = 'gnd']/tei:term/tei:ref" mode="m_fileDesc-to-biblStruct">
        <idno type="gnd">
            <xsl:value-of select="@target"/>
        </idno>
    </xsl:template>
    <xsl:template match="@scheme" mode="m_fileDesc-to-biblStruct" priority="10">
        <xsl:attribute name="source">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="@n" mode="m_fileDesc-to-biblStruct" priority="10">
        <xsl:attribute name="type" select="."/>
    </xsl:template>
    <xsl:template match="tei:idno[@type = ('volume', 'issue')]" mode="m_fileDesc-to-biblStruct">
        <biblScope unit="{@type}">
            <xsl:choose>
                <xsl:when test="number(.)">
                    <xsl:attribute name="from" select="format-number(., '1')"/>
                    <xsl:attribute name="to" select="format-number(., '1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </biblScope>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'DHQarticle-id']" mode="m_fileDesc-to-biblStruct">
        <xsl:variable name="v_id" select="normalize-space(.)"/>
        <idno>
            <xsl:apply-templates mode="m_identity-transform" select="@type"/>
            <xsl:value-of select="$v_id"/>
        </idno>
        <xsl:variable name="v_base-url"
            select="concat('https://digitalhumanities.org/dhq/vol/', following-sibling::tei:idno[@type = 'volume'], '/', normalize-space(following-sibling::tei:idno[@type = 'issue']), '/', $v_id, '/', $v_id)"/>
        <idno type="URI">
            <xsl:value-of select="concat($v_base-url, '.html')"/>
        </idno>
        <idno type="URI">
            <xsl:value-of select="concat($v_base-url, '.xml')"/>
        </idno>
    </xsl:template>
    <xsl:template match="dhq:authorInfo" mode="m_dhq-to-biblStruct">
        <author>
            <persName>
                <xsl:variable name="v_name">
                    <xsl:apply-templates mode="m_plain-text" select="dhq:author_name/text()"/>
                </xsl:variable>
                <forename>
                    <xsl:value-of select="normalize-space($v_name)"/>
                </forename>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="m_dhq-to-biblStruct" select="dhq:author_name/dhq:family"/>
            </persName>
            <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="tei:idno"/>
            <xsl:apply-templates mode="m_dhq-to-biblStruct" select=".//tei:ref[matches(@target, 'https*://orcid.org')]"/>
            <xsl:apply-templates mode="m_dhq-to-biblStruct" select="dhq:affiliation"/>
        </author>
    </xsl:template>
    <xsl:template match="dhq:affiliation" mode="m_dhq-to-biblStruct">
        <xsl:variable name="v_plain">
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </xsl:variable>
        <affiliation>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </affiliation>
    </xsl:template>
    <xsl:template match="dhq:family" mode="m_dhq-to-biblStruct">
        <xsl:variable name="v_name">
            <xsl:apply-templates mode="m_plain-text" select="text()"/>
        </xsl:variable>
        <surname>
            <xsl:value-of select="normalize-space($v_name)"/>
        </surname>
    </xsl:template>
    <xsl:template match="dhq:authorInfo//tei:ref[matches(@target, 'https*://orcid.org')]" mode="m_dhq-to-biblStruct">
        <idno type="ORCID">
            <xsl:value-of select="replace(@target, 'https*://orcid.org/(.+)$', '$1')"/>
        </idno>
    </xsl:template>
    <xsl:template match="tei:title[parent::tei:titleStmt]" mode="m_fileDesc-to-biblStruct">
        <!--        <xsl:choose>-->
        <!-- some titles nest. for instance, in the case of reviews -->
        <!--<xsl:when test="tei:title">
                <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="tei:title"/>
            </xsl:when>-->
        <!--            <xsl:otherwise>-->
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:attribute name="level" select="'a'"/>
            <xsl:attribute name="xml:lang">
                <xsl:choose>
                    <xsl:when test="@xml:lang">
                        <xsl:value-of select="@xml:lang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="ancestor::tei:TEI/tei:text/@xml:lang"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </xsl:copy>
        <!--</xsl:otherwise>-->
        <!--</xsl:choose>-->
    </xsl:template>
    <xsl:template match="tei:author | tei:date | tei:idno | tei:publisher | tei:title" mode="m_fileDesc-to-biblStruct">
        <xsl:apply-templates mode="m_identity-transform" select="."/>
    </xsl:template>
    <!-- clean ORCID -->
    <xsl:template match="tei:idno[matches(@type, 'orcid', 'i')]" mode="m_fileDesc-to-biblStruct m_simple" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:value-of select="replace(., 'https*://orcid.org/(.+)$', '$1')"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="text()[. = 'NA'] | tei:title/@ref | tei:title/@resp" mode="m_simple"/>
    <!-- the following two templates are based on authority control and can be safely removed if this isn't needed -->
    <!--<xsl:template match="tei:pubPlace[tei:placeName[@ref][@ref != 'NA']]" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates mode="m_simple" select="@*"/>
            <!-\- look-up toponym for the reference's language in the authority file -\->
            <xsl:copy-of select="
                    oape:query-gazetteer(tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'name-tei', if (ancestor::tei:monogr/tei:textLang[1]/@mainLang) then
                        (ancestor::tei:monogr/tei:textLang[1]/@mainLang)
                    else
                        ('en'))"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:editor[tei:persName[@ref][@ref != 'NA']]" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates mode="m_simple" select="@*"/>
            <!-\- look-up the editor's name for the reference's language in the authority file -\->
            <xsl:apply-templates mode="m_simple" select="
                    oape:query-personography(tei:persName[@ref][1], $v_personography, $p_local-authority, 'name-tei', if (ancestor::tei:monogr/tei:textLang[1]/@mainLang) then
                        (ancestor::tei:monogr/tei:textLang[1]/@mainLang)
                    else
                        ('en'))"/>
        </xsl:copy>
    </xsl:template>-->
</xsl:stylesheet>
