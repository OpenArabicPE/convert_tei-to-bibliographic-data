<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0" name="xml"/>
    
    <xsl:include href="parameters.xsl"/>
    <xsl:import href="../../authority-files/xslt/functions.xsl"/>
    
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
        <xsl:variable name="v_bibtex-key" select="concat($v_id-file,'-',$v_id-div)"/>
        <xsl:element name="biblStruct">
            <xsl:element name="analytic">
                <!-- article title -->
                <xsl:element name="title">
                    <xsl:attribute name="level" select="'a'"/>
                    <xsl:attribute name="xml:lang" select="$p_div/@xml:lang"/>
                    <!-- with a single head, this function still returns two strings (the second is empty) -->
                    <xsl:value-of select="oape:get-title-from-div($p_div, if($v_source-monogr/tei:title/@level = 'm') then(false()) else(true()))"/>
                </xsl:element>
                <!-- authorship  information -->
                <!-- if the input is not a periodical but a book, the book's author should be replicated here -->
                <xsl:choose>
                    <xsl:when test="$v_source-monogr/tei:title/@level = 'm'">
                        <xsl:apply-templates select="$v_source-monogr/descendant::tei:author" mode="m_replicate"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="author">
                            <xsl:apply-templates select="oape:get-author-from-div($p_div)" mode="m_replicate"/>
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
                <xsl:for-each select="$p_div/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='url']">
                    <xsl:element name="idno">
                        <xsl:attribute name="type" select="'url'"/>
                        <xsl:value-of select="concat(.,'#',$v_id-div)"/>
                    </xsl:element>
                </xsl:for-each>
                <!-- add gh-pages -->
                <xsl:if test="not($p_div/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='url'][contains(.,'.github.io/')])">
                        <xsl:element name="idno">
                            <xsl:attribute name="type" select="'url'"/>
                            <xsl:value-of select="concat( oape:transform-url-github-gh-pages($p_div/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='url'][not(contains(., '.github.io/'))]),'#',$v_id-div)"/>
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
                <xsl:apply-templates select="$v_source-monogr/tei:title" mode="m_replicate"/>
                <!-- IDs -->
                <xsl:apply-templates select="$v_source-monogr/tei:idno" mode="m_replicate"/>
                <!-- add file name as ID -->
                <xsl:element name="tei:idno">
                    <xsl:attribute name="type" select="'URI'"/>
                    <xsl:value-of select="$v_id-file"/>
                </xsl:element>
                <!-- text languages -->
                <xsl:choose>
                    <xsl:when test="$v_source-monogr/tei:textLang">
                        <xsl:apply-templates select="$v_source-monogr/tei:textLang" mode="m_replicate"/>
                    </xsl:when>
                    <xsl:when test="$p_div/@xml:lang">
                        <xsl:element name="tei:textLang">
                            <xsl:attribute name="mainLang" select="$p_div/@xml:lang"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
                <!-- editor -->
                <xsl:apply-templates select="$v_source-monogr/tei:editor" mode="m_replicate"/>
                <!-- imprint -->
                <xsl:apply-templates select="$v_source-monogr/tei:imprint" mode="m_replicate"/>
                <!-- volume and issue -->
                <xsl:apply-templates select="$v_source-monogr/tei:biblScope[not(@unit='page')]" mode="m_replicate"/>
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
                    <xsl:value-of select="concat($v_page-onset,'-',$v_page_terminus)"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:function>
    
    <!-- function to get the author(s) of a div -->
    <xsl:function name="oape:get-author-from-div">
        <xsl:param name="p_div"/>
        <xsl:choose>
            <xsl:when
                test="$p_div/child::tei:byline/descendant::tei:persName[not(ancestor::tei:note)]">
                <xsl:copy-of
                    select="$p_div/child::tei:byline/descendant::tei:persName[not(ancestor::tei:note)]"
                />
            </xsl:when>
            <xsl:when
                test="$p_div/child::tei:byline/descendant::tei:orgName[not(ancestor::tei:note)]">
                <xsl:copy-of
                    select="$p_div/child::tei:byline/descendant::tei:orgName[not(ancestor::tei:note)]"
                />
            </xsl:when>
            <!-- there is a problem here: sections will inherit all the authors of the contained items -->
            <xsl:when
                test="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:author">
                <xsl:copy-of
                    select="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:author/descendant::tei:persName"
                />
            </xsl:when>
            <xsl:when
                test="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:title[@level = 'j']">
                <xsl:copy-of
                    select="$p_div/descendant::tei:note[@type = 'bibliographic'][ancestor::tei:div[1] = $p_div]/tei:bibl/tei:title[@level = 'j']"
                />
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
                <xsl:apply-templates select="$p_div/ancestor::tei:div[@type = 'section']/tei:head"
                    mode="m_tei-to-biblstruct"/>
                <xsl:text>: </xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:apply-templates select="$p_div/tei:head" mode="m_tei-to-biblstruct"/>
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
        <xsl:analyze-string select="$p_url" regex="https*://github\.com/(\w+)/(.+?)/blob/master/(.+\.xml)">
            <xsl:matching-substring>
                        <xsl:value-of select="concat('https://',regex-group(1),'.github.io/',regex-group(2),'/',regex-group(3))"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
    </xsl:function>
    
    <xsl:template match="node()" mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_replicate"/>
            <!-- add missing language information -->
            <xsl:if test="not(@xml:lang) and ancestor::node()[@xml:lang != ''][1]/@xml:lang">
                <xsl:attribute name="xml:lang" select="ancestor::node()[@xml:lang != ''][1]/@xml:lang"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="m_replicate"/>
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
                    <xsl:value-of select="concat(@source, ' ', $v_url-file, '#', @xml:id)"/>
                </xsl:when>
                <xsl:otherwise>
                    <!--                    <xsl:value-of select="concat(base-uri(), '#', @xml:id)"/>-->
                    <xsl:value-of select="concat($v_url-file, '#', @xml:id)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- publication date of the source file -->
        <xsl:variable name="v_source-date" select="document($v_url-file)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/descendant::tei:biblStruct[1]/descendant::tei:date[@when][1]/@when"/>
        <biblStruct>
            <xsl:apply-templates mode="m_replicate" select="@*"/>
            <!-- document source of information -->
            <xsl:attribute name="source" select="$v_source"/>
            <xsl:if test="tei:title[@level = 'a']">
                <analytic>
                    <xsl:apply-templates mode="m_replicate" select="tei:title[@level = 'a']"/>
                    <xsl:apply-templates mode="m_replicate" select="tei:author"/>
                </analytic>
            </xsl:if>
            <monogr>
                <xsl:apply-templates mode="m_replicate" select="tei:title[@level != 'a']"/>
                <xsl:apply-templates mode="m_replicate" select="tei:idno"/>
                <xsl:for-each select="tokenize(tei:title[@level != 'a'][@ref][1]/@ref, '\s+')">
                    <xsl:variable name="v_authority">
                        <xsl:choose>
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
                            <xsl:when test="contains(., 'oclc:')">
                                <xsl:value-of select="replace(., '.*oclc:(\d+).*', '$1')"/>
                            </xsl:when>
                            <xsl:when test="contains(., $v_local-uri-scheme)">
                                <!-- local IDs in Project Jaraid are not nummeric for biblStructs -->
                                <xsl:value-of select="replace(., concat('.*', $v_local-uri-scheme, '(\w+).*'), '$1')"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <idno type="{$v_authority}">
                        <xsl:value-of select="$v_idno"/>
                    </idno>
                </xsl:for-each>
                <xsl:choose>
                    <xsl:when test="tei:textLang">
                        <xsl:apply-templates mode="m_replicate" select="tei:textLang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <textLang>
                            <xsl:attribute name="mainLang">
                                <xsl:choose>
                                    <xsl:when test="tei:title[@level != 'a']/@xml:lang">
                                        <xsl:value-of select="tei:title[@level != 'a'][@xml:lang][1]/@xml:lang"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>ar</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </textLang>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- author: depending on which level we are on -->
                <xsl:choose>
                    <!-- if this is for a book section, article etc., the author has been part of <analytic> -->
                    <xsl:when test="tei:title[@level = 'a']"/>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_replicate" select="tei:author"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates mode="m_replicate" select="tei:editor"/>
                <imprint>
                    <xsl:apply-templates mode="m_replicate" select="descendant::tei:date"/>
                    <!-- add a date at which this bibl was documented in the source file -->
                    <date type="documented" when="{$v_source-date}"/>
                    <xsl:apply-templates mode="m_replicate" select="tei:pubPlace"/>
                    <xsl:apply-templates mode="m_replicate" select="tei:publisher"/>
                </imprint>
                <xsl:apply-templates mode="m_replicate" select="tei:biblScope"/>
            </monogr>
        </biblStruct>
    </xsl:template>
    <!-- produce simple derivates of tei:biblStruct -->
    <xsl:template match="tei:biblStruct" mode="m_simple">
        <xsl:copy>
            <!-- select attributes -->
            <xsl:apply-templates select="@* | node()" mode="m_simple"/>
        </xsl:copy>
    </xsl:template>
    <!-- excluded attributes  -->
    <xsl:template match="@change | @resp | @xml:id  | @xml:lang[parent::tei:biblScope | parent::tei:biblStruct |parent::tei:date | parent::tei:editor | parent::tei:publisher | parent::tei:pubPlace] | @source[parent::tei:idno | parent::tei:monogr | parent::tei:orgName | parent::tei:persName] | tei:editor/@ref  | tei:persName/@type" mode="m_simple"/>
    <!-- excluded nodes -->
    <xsl:template match="tei:biblStruct/tei:note | tei:monogr/tei:respStmt" mode="m_simple"/>
    <!-- reduce nodes to machine readability -->
    <xsl:template match="tei:date" mode="m_simple">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="@when | @notBefore | @notAfter">
                    <xsl:apply-templates select="@*" mode="m_simple"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="m_simple"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblScope" mode="m_simple">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="@unit and @from and @to">
                    <xsl:apply-templates select="@*" mode="m_simple"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="m_simple"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!-- reduce children -->
    <xsl:template match="tei:monogr" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_simple"/>
            <xsl:apply-templates select="tei:title" mode="m_simple"/>
            <xsl:apply-templates select="tei:idno" mode="m_simple">
                <xsl:sort select="@type"/>
                <xsl:sort select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="tei:textLang" mode="m_simple"/>
            <xsl:apply-templates select="tei:editor" mode="m_simple"/>
            <xsl:apply-templates select="tei:imprint" mode="m_simple"/>
            <xsl:apply-templates select="tei:biblScope" mode="m_simple"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:imprint" mode="m_simple">
        <xsl:copy>
            <!-- date -->
            <xsl:choose>
                <xsl:when test="tei:date[@when | @notAfter | @notBefore]/@type = 'onset'">
                    <xsl:apply-templates select="tei:date[@when | @notAfter | @notBefore][@type = 'onset']" mode="m_simple"/>
                </xsl:when>
                <xsl:when test="tei:date[@type = 'onset']">
                    <xsl:apply-templates select="tei:date[@type = 'onset']" mode="m_simple"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="tei:pubPlace[1] | tei:publisher[1]" mode="m_simple"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:pubPlace[tei:placeName[@ref][@ref != 'NA']]" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_simple"/>
            <!-- generate two toponyms from the authority file -->
            <xsl:copy-of select="oape:query-gazetteer(tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'name-tei', 'ar')"/>
            <xsl:copy-of select="oape:query-gazetteer(tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'name-tei', 'en')"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:editor[tei:persName[@ref][@ref != 'NA']]" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_simple"/>
            <!-- generate two toponyms from the authority file -->
            <xsl:apply-templates select="oape:query-personography(tei:persName[@ref][1], $v_personography, $p_local-authority, 'name-tei', 'ar')" mode="m_simple"/>
            <xsl:apply-templates select="oape:query-personography(tei:persName[@ref][1], $v_personography, $p_local-authority, 'name-tei', 'ar-Latn-x-ijmes')" mode="m_simple"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:surname" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_simple"/>
            <xsl:apply-templates select="text()" mode="m_simple"/>
        </xsl:copy>
    </xsl:template>
    <!-- replicate everything that has not been excluded -->
    <xsl:template match="node()" mode="m_simple">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_simple"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@*" mode="m_simple m_replicate">
            <xsl:if test="string-length(.)!=0">
                <xsl:copy/>
            </xsl:if>
    </xsl:template>
    
    
</xsl:stylesheet>
