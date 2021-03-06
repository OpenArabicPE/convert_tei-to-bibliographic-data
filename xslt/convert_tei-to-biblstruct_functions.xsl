<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0" name="xml"/>
    
    <xsl:include href="parameters.xsl"/>
    
    <!-- are translators covered? -->
    
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
    
    <xsl:template match="node() | @*" mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_replicate"/>
            <!-- add missing language information -->
            <xsl:if test="not(@xml:lang)">
                <xsl:attribute name="xml:lang" select="ancestor::node()[@xml:lang != ''][1]/@xml:lang"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_replicate"/>
</xsl:stylesheet>
