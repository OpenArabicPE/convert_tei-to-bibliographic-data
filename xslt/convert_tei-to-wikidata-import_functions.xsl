<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.wikidata.org/" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:import href="../../authority-files/xslt/functions.xsl"/>
    <xsl:import href="functions.xsl"/>
    <!-- This stylesheets transform bibliographic data from TEI/XML to a custom Wikidata XML format, which utilises Property IDs as element names for easy import and reconciliation with OpenRefine -->
    <!-- to do
        - [x] Wikidata does not know about transliterations. Therefore, we have to translate BCP47 language-script codes to simpler ISO 629-2 codes
        - [x] resolve orgs in @ref
        - [ ] date[@type = 'documented']
        - periodicals published in Istanbul
        - idno/@type: not yet converted
            - [ ] url
            - [ ] urn
            - [ ] DOI
    -->
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@*[not(name() = 'source')]"/>
            <xsl:apply-templates select="@source"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="element()[not(attribute())][not(text())][not(element())]" mode="m_tei2wikidata" priority="2"/>
    <!--  remove attributes  -->
    <xsl:template
        match="@change | @resp | @source | @xml:id | @oape:weekday | tei:biblStruct/@xml:lang | tei:monogr/@next | tei:monogr/@prev | tei:monogr/@xml:lang | tei:title/@level | tei:title/@ref"
        mode="m_tei2wikidata"/>
    <!-- remove nodes -->
    <xsl:template match="tei:date[@type = 'documented']" mode="m_tei2wikidata"/>
    <xsl:template match="tei:note[@type = ('comments', 'sources', 'holdings')]" mode="m_tei2wikidata"/>
    <!-- convert textual content to a string node -->
    <xsl:template name="t_string-value">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_text">
            <xsl:for-each select="$p_input/descendant-or-self::text()">
                <xsl:value-of select="concat(' ', ., ' ')"/>
            </xsl:for-each>
        </xsl:variable>
        <string>
            <xsl:apply-templates mode="m_tei2wikidata" select="$p_input/@xml:lang"/>
            <xsl:value-of select="normalize-space($v_text)"/>
        </string>
        <!-- provide transliterations, if possible in P2440 -->
        <!--<xsl:if test="$p_input/@xml:lang = 'ar' and $p_input/parent::node()/child::node()[local-name() = current()/local-name()][contains(@xml:lang, 'ar-Latn')]">
            <xsl:if test="$p_debug = true()">
                <xsl:message>
                    <xsl:text>P2440</xsl:text>
                </xsl:message>
            </xsl:if>
            <!-\- this will only reliably work for title -\->
            <xsl:for-each select="$p_input/parent::node()/child::node()[local-name() = current()/local-name()][contains(@xml:lang, 'ar-Latn')]">
                <P2440>
                    <xsl:value-of select="."/>
                </P2440>
            </xsl:for-each>
        </xsl:if>-->
    </xsl:template>
    <xsl:template name="t_QItem">
        <xsl:param name="p_input"/>
        <QItem>
            <xsl:value-of select="normalize-space($p_input)"/>
        </QItem>
    </xsl:template>
    <xsl:template name="t_source">
        <xsl:param as="node()" name="p_input"/>
        <xsl:variable name="v_source" select="
                if ($p_input/@source) then
                    ($p_input/@source)
                else
                    (ancestor::node()[@source][1]/@source)"/>
        <xsl:for-each-group group-by="." select="tokenize($v_source, '\s+')">
            <xsl:variable name="v_source" select="current-grouping-key()"/>
            <!-- reference URL: P854 -->
            <xsl:choose>
                <xsl:when test="starts-with($v_source, 'http')">
                    <P854>
                        <xsl:value-of select="$v_source"/>
                    </P854>
                </xsl:when>
                <!-- local URLs need to be resolved or omitted -->
                <xsl:when test="starts-with($v_source, '../')">
                    <xsl:choose>
                        <xsl:when test="matches($v_source, 'oclc_618896732/|oclc_165855925/')">
                            <P854>
                                <xsl:value-of select="replace($v_source, '^(\.\./)+TEI/', 'https://tillgrallert.github.io/')"/>
                            </P854>
                        </xsl:when>
                        <xsl:when test="matches($v_source, '/OpenArabicPE/')">
                            <P854>
                                <xsl:value-of select="replace($v_source, '^^(\.\./)+OpenArabicPE/', 'https://openarabicpe.github.io/')"/>
                            </P854>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>
                                <xsl:text>WARNING: </xsl:text>
                                <xsl:value-of select="$v_source"/>
                                <xsl:text> could not be resolved</xsl:text>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="starts-with($v_source, concat($p_local-authority, ':org:'))">
                    <xsl:variable name="v_orgName">
                        <tei:orgName ref="{$v_source}"/>
                    </xsl:variable>
                    <!-- query the organisationography -->
                    <xsl:variable name="v_url" select="oape:query-organizationography($v_orgName/descendant-or-self::tei:orgName, $v_organizationography, $p_local-authority, 'url', 'en')"/>
                    <xsl:choose>
                        <xsl:when test="$v_url != 'NA'">
                            <P854>
                                <xsl:value-of select="$v_url"/>
                            </P854>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>
                                <xsl:text>WARNING: no URL for </xsl:text>
                                <xsl:value-of select="$v_source"/>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- local bibliographies -->
                <xsl:when test="matches($v_source, ':bibl:')">
                    <xsl:variable name="v_title">
                        <tei:title ref="{$v_source}"/>
                    </xsl:variable>
                    <xsl:variable name="v_id-wiki" select="oape:query-bibliography($v_title/tei:title, $v_bibliography, '', $p_local-authority, 'id-wiki', '')"/>
                    <xsl:choose>
                        <xsl:when test="$v_id-wiki != 'NA'">
                            <P248>
                                <xsl:value-of select="$v_id-wiki"/>
                            </P248>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>WARNING: could not find a QID for "</xsl:text>
                            <xsl:value-of select="$v_source"/>
                            <xsl:text>" in our bibliography</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- stated in: P248, requires a QItem -->
                <xsl:when test="matches($v_source, 'Q\d+')">
                    <P248>
                        <xsl:value-of select="replace($v_source, '^.*(Q\d+).*$', '$1')"/>
                    </P248>
                </xsl:when>
                <!-- remove pandoc references -->
                <xsl:when test="starts-with($v_source, '@')"/>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>WARNING: the source "</xsl:text>
                        <xsl:value-of select="$v_source"/>
                        <xsl:text>" is not yet supported</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:template>
    <!-- nodes to be converted -->
    <xsl:template match="tei:biblScope" mode="m_tei2wikidata"/>
    <xsl:template match="tei:biblStruct" mode="m_tei2wikidata">
        <item>
            <xsl:choose>
                <xsl:when test="descendant::tei:idno[@type = $p_acronym-wikidata]">
                    <xsl:attribute name="xml:id" select="descendant::tei:idno[@type = $p_acronym-wikidata][1]"/>
                </xsl:when>
                <xsl:when test="descendant::tei:title[matches(@ref, $p_acronym-wikidata)]">
                    <xsl:attribute name="xml:id" select="replace(descendant::tei:title[matches(@ref, $p_acronym-wikidata)][1]/@ref, '^.*(Q\d+).*$', '$1')"/>
                </xsl:when>
                <xsl:when test="descendant::tei:idno[@type = $p_local-authority]">
                    <xsl:attribute name="xml:id" select="concat($p_local-authority, '_', descendant::tei:idno[@type = $p_local-authority][1])"/>
                </xsl:when>
                <xsl:otherwise>
                    <!--                    <xsl:attribute name="xml:id" select="concat('temp_', generate-id(.))"/>-->
                    <xsl:message terminate="yes">
                        <xsl:text>The biblStruct has no ID that would alow to link back to it</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <!-- add label and description -->
            <xsl:variable name="v_onset" select="oape:query-biblstruct(., 'year-onset', '', $v_gazetteer, $p_local-authority)"/>
            <xsl:variable name="v_terminus" select="oape:query-biblstruct(., 'year-terminus', '', $v_gazetteer, $p_local-authority)"/>
            <label xml:lang="en">
                <xsl:value-of select="oape:query-biblstruct(., 'title', 'ar-Latn-x-ijmes', $v_gazetteer, $p_local-authority)"/>
            </label>
            <description xml:lang="en">
                <xsl:choose>
                    <xsl:when test="@subtype = 'journal'">
                        <xsl:text>magazine</xsl:text>
                    </xsl:when>
                    <xsl:when test="@subtype = 'newspaper'">
                        <xsl:value-of select="@subtype"/>
                    </xsl:when>
                    <xsl:when test="@type = 'periodical' or descendant::tei:title[@level = 'j']">
                        <xsl:value-of select="@type"/>
                    </xsl:when>
                </xsl:choose>
                <xsl:text> published </xsl:text>
                <xsl:if test="descendant::tei:pubPlace/tei:placeName/@ref">
                    <xsl:text>in </xsl:text>
                    <xsl:value-of select="oape:query-biblstruct(., 'pubPlace', 'en', $v_gazetteer, $p_local-authority)"/>
                </xsl:if>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$v_onset != 'NA' and $v_terminus != 'NA'">
                        <xsl:text>between </xsl:text>
                        <xsl:value-of select="$v_onset"/>
                        <xsl:text> and </xsl:text>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:when>
                    <xsl:when test="$v_onset != 'NA' and $v_terminus = 'NA'">
                        <xsl:text>from </xsl:text>
                        <xsl:value-of select="$v_onset"/>
                        <xsl:text> onwards</xsl:text>
                    </xsl:when>
                    <xsl:when test="$v_onset = 'NA' and $v_terminus != 'NA'">
                        <xsl:text>until </xsl:text>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:when>
                </xsl:choose>
            </description>
            <label xml:lang="ar">
                <xsl:value-of select="oape:query-biblstruct(., 'title', 'ar', $v_gazetteer, $p_local-authority)"/>
            </label>
            <description xml:lang="ar">
                <xsl:choose>
                    <xsl:when test="@subtype = 'journal'">
                        <xsl:text>مجلة</xsl:text>
                    </xsl:when>
                    <xsl:when test="@subtype = 'newspaper'">
                        <xsl:text>جريدة</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'periodical' or descendant::tei:title[@level = 'j']">
                        <xsl:text>دورية</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:text> تصدر </xsl:text>
                <xsl:if test="descendant::tei:pubPlace/tei:placeName/@ref">
                    <xsl:text>في </xsl:text>
                    <xsl:value-of select="oape:query-biblstruct(., 'pubPlace', 'ar', $v_gazetteer, $p_local-authority)"/>
                </xsl:if>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$v_onset != 'NA' and $v_terminus != 'NA'">
                        <xsl:text>بين سنة </xsl:text>
                        <xsl:value-of select="$v_onset"/>
                        <xsl:text> و </xsl:text>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:when>
                    <xsl:when test="$v_onset != 'NA' and $v_terminus = 'NA'">
                        <xsl:text>منذ سنة </xsl:text>
                        <xsl:value-of select="$v_onset"/>
                    </xsl:when>
                    <xsl:when test="$v_onset = 'NA' and $v_terminus != 'NA'">
                        <xsl:text>حتى سنة </xsl:text>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:when>
                </xsl:choose>
            </description>
            <xsl:apply-templates mode="m_tei2wikidata" select="@* | node()"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:biblStruct" mode="m_tei2wikidata_holdings">
        <item>
            <xsl:choose>
                <xsl:when test="descendant::tei:idno[@type = 'wiki']">
                    <xsl:attribute name="xml:id" select="descendant::tei:idno[@type = 'wiki'][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="xml:id" select="concat($p_local-authority, '_', descendant::tei:idno[@type = $p_local-authority][1])"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates mode="m_tei2wikidata" select="tei:monogr/tei:idno[@type = $p_acronym-wikidata]"/>
            <!-- holdings -->
            <xsl:apply-templates mode="m_tei2wikidata_holdings" select="tei:note[@type = 'holdings']"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:biblStruct/@subtype | tei:biblStruct/@type" mode="m_tei2wikidata">
        <P31>
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test=". = 'journal'">
                    <!-- mapped to "magazine" -->
                    <QItem>Q41298</QItem>
                </xsl:when>
                <xsl:when test=". = 'newspaper'">
                    <QItem>Q11032</QItem>
                </xsl:when>
                <xsl:when test=". = 'periodical'">
                    <QItem>Q1002697</QItem>
                </xsl:when>
            </xsl:choose>
        </P31>
    </xsl:template>
    <xsl:template match="tei:date[@type = ('onset', 'official')]" mode="m_tei2wikidata">
        <!-- inception -->
        <P571>
            <xsl:apply-templates mode="m_date-when" select="."/>
        </P571>
        <!-- start time -->
        <P580>
            <xsl:apply-templates mode="m_date-when" select="."/>
        </P580>
    </xsl:template>
    <xsl:template match="tei:date[@type = 'terminus']" mode="m_tei2wikidata">
        <!-- end time -->
        <P582>
            <xsl:apply-templates mode="m_date-when" select="."/>
        </P582>
    </xsl:template>
    <!-- aggregate data on the entire collection: note that there is a "single best value" constraint on this -->
    <xsl:template match="tei:date" mode="m_tei2wikidata_holdings">
        <xsl:choose>
            <xsl:when test="@type = ('onset')">
                <!-- start time -->
                <P580>
                    <xsl:apply-templates mode="m_date-when" select="."/>
                </P580>
            </xsl:when>
            <xsl:when test="@type = ('terminus')">
                <!-- start time -->
                <P582>
                    <xsl:apply-templates mode="m_date-when" select="."/>
                </P582>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>date: @type not present or not supported</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:date[ancestor::tei:biblStruct][1]/tei:monogr/tei:title[@level = 'm']" mode="m_tei2wikidata">
        <P577>
            <xsl:apply-templates mode="m_date-when" select="."/>
        </P577>
    </xsl:template>
    <xsl:template match="tei:date" mode="m_date-when">
        <xsl:call-template name="t_source">
            <xsl:with-param name="p_input" select="."/>
        </xsl:call-template>
        <xsl:if test="@when">
            <date>
                <xsl:value-of select="@when"/>
            </date>
        </xsl:if>
        <xsl:if test="matches(@notAfter, '\d{4}-\d{2}-[29|30|31]') and (month-from-date(@notAfter) = month-from-date(@notBefore))">
            <date>
                <xsl:value-of select="replace(@notAfter, '(\d{4}-\d{2})-\d+', '$1')"/>
            </date>
        </xsl:if>
        <!-- notBefore: P1319, earliest date -->
        <xsl:if test="@notBefore">
            <P1319>
                <date>
                    <xsl:value-of select="@notBefore"/>
                </date>
            </P1319>
        </xsl:if>
        <!-- notAfter: P1326, latest date -->
        <xsl:if test="@notAfter">
            <P1326>
                <date>
                    <xsl:value-of select="@notAfter"/>
                </date>
            </P1326>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:editor[tei:orgName]" mode="m_tei2wikidata"/>
    <xsl:template match="tei:editor[tei:persName]" mode="m_tei2wikidata">
        <!-- converting to a reconciled Wikidata item! -->
        <xsl:variable name="v_id-wiki" select="oape:query-personography(tei:persName[1], $v_personography, $p_local-authority, 'id-wiki', '')"/>
        <xsl:variable name="v_id-viaf" select="oape:query-personography(tei:persName[1], $v_personography, $p_local-authority, 'id-viaf', '')"/>
        <xsl:choose>
            <xsl:when test="$v_id-wiki != 'NA' or $v_id-viaf != 'NA'">
                <xsl:if test="@type = 'owner'">
                    <!-- P112: founded by -->
                    <P112>
                        <xsl:call-template name="t_editors">
                            <xsl:with-param name="p_persName" select="tei:persName[1]"/>
                            <xsl:with-param name="p_id-wiki" select="$v_id-wiki"/>
                            <xsl:with-param name="p_id-viaf" select="$v_id-viaf"/>
                        </xsl:call-template>
                    </P112>
                    <!-- P127: owned by -->
                    <P127>
                        <xsl:call-template name="t_editors">
                            <xsl:with-param name="p_persName" select="tei:persName[1]"/>
                            <xsl:with-param name="p_id-wiki" select="$v_id-wiki"/>
                            <xsl:with-param name="p_id-viaf" select="$v_id-viaf"/>
                        </xsl:call-template>
                    </P127>
                </xsl:if>
                <!-- P98: editor -->
                <P98>
                    <xsl:call-template name="t_editors">
                        <xsl:with-param name="p_persName" select="tei:persName[1]"/>
                        <xsl:with-param name="p_id-wiki" select="$v_id-wiki"/>
                        <xsl:with-param name="p_id-viaf" select="$v_id-viaf"/>
                    </xsl:call-template>
                </P98>
            </xsl:when>
            <xsl:otherwise>
                <!-- select based on the main language -->
                <xsl:choose>
                    <xsl:when test="tei:persName/@xml:lang = ancestor::tei:monogr[1]/tei:textLang/@mainLang">
                        <xsl:apply-templates mode="m_name-string" select="tei:persName[@xml:lang = ancestor::tei:monogr[1]/tei:textLang/@mainLang][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_name-string" select="tei:persName[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="t_editors">
        <xsl:param name="p_persName"/>
        <xsl:param name="p_id-wiki"/>
        <xsl:param name="p_id-viaf"/>
        <xsl:call-template name="t_source">
            <xsl:with-param name="p_input" select="."/>
        </xsl:call-template>
        <xsl:choose>
            <!-- linked to Wikidata -->
            <xsl:when test="$p_id-wiki != 'NA'">
                <xsl:call-template name="t_QItem">
                    <xsl:with-param name="p_input" select="$p_id-wiki"/>
                </xsl:call-template>
            </xsl:when>
            <!-- linked to VIAF -->
            <xsl:when test="$p_id-viaf != 'NA'">
                <xsl:call-template name="t_string-value">
                    <xsl:with-param name="p_input" select="$p_persName"/>
                </xsl:call-template>
                <P214>
                    <xsl:value-of select="$p_id-viaf"/>
                </P214>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:persName[parent::tei:editor]" mode="m_name-string">
        <P2093>
            <xsl:apply-templates mode="m_string" select="."/>
        </P2093>
    </xsl:template>
    <xsl:template match="tei:idno" mode="m_tei2wikidata">
        <xsl:choose>
            <xsl:when test="@type = 'ISBN'">
                <xsl:choose>
                    <xsl:when test="matches(., '^\d{13}$')">
                        <P212>
                            <xsl:apply-templates mode="m_string" select="."/>
                        </P212>
                    </xsl:when>
                    <xsl:when test="matches(., '^\d{10}$')">
                        <P957>
                            <xsl:apply-templates mode="m_string" select="."/>
                        </P957>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>WARNING: unexpectedly formatted ISBN: </xsl:text>
                            <xsl:value-of select="."/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="@type = 'isil'">
                <P791>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P791>
            </xsl:when>
            <xsl:when test="@type = 'ISSN'">
                <P236>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P236>
            </xsl:when>
            <xsl:when test="@type = 'jid'">
                <P953>
                    <xsl:apply-templates mode="m_string" select="concat($p_url-resolve-jid, .)"/>
                </P953>
            </xsl:when>
            <xsl:when test="@type = 'ht_bib_key'">
                <P1844>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P1844>
            </xsl:when>
            <xsl:when test="@type = 'LCCN'">
                <P1144>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P1144>
            </xsl:when>
            <xsl:when test="@type = 'OCLC'">
                <P243>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P243>
            </xsl:when>
            <!-- untyped catalogue IDs -->
            <xsl:when test="@type = 'record'">
                <xsl:choose>
                    <!-- National Library of Israel -->
                    <xsl:when test="@source = ('https://www.nli.org.il/', 'oape:org:60')">
                        <P8189>
                            <xsl:apply-templates mode="m_string" select="."/>
                        </P8189>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="@type = 'shamela'">
                <P953>
                    <xsl:apply-templates mode="m_string" select="concat($p_url-resolve-shamela, .)"/>
                </P953>
            </xsl:when>
            <xsl:when test="@type = 'VIAF'">
                <P214>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P214>
            </xsl:when>
            <xsl:when test="@type = 'wiki'">
                <xsl:call-template name="t_QItem">
                    <xsl:with-param name="p_input" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="@type = 'zdb'">
                <P1042>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P1042>
            </xsl:when>
            <xsl:when test="@type = 'zenodo'">
                <P4901>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P4901>
            </xsl:when>
            <!-- Identifiers that should be skipped -->
            <xsl:when test="@type = ('jaraid', 'oape', 'AUBNO', 'aub', 'classmark', 'eap', 'epub', 'fid', 'LEAUB')"/>
            <!-- URIs and URLs -->
            <xsl:when test="@type = 'URI'">
                <P953>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P953>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>WARNING: unknown idno of type "</xsl:text>
                    <xsl:value-of select="@type"/>
                    <xsl:text>" is not converted</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:imprint" mode="m_tei2wikidata">
        <xsl:apply-templates mode="m_tei2wikidata" select="node()"/>
    </xsl:template>
    <xsl:template match="tei:monogr" mode="m_tei2wikidata">
        <xsl:apply-templates mode="m_tei2wikidata" select="@oape:frequency | node()"/>
    </xsl:template>
    <xsl:template match="tei:monogr[@type = 'reprint']" mode="m_tei2wikidata"/>
    <xsl:template match="tei:publisher" mode="m_tei2wikidata">
        <!-- converting to a reconciled Wikidata item! -->
        <xsl:choose>
            <xsl:when test="node()[matches(@ref, 'wiki:Q\d+')]">
                <P123>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="node()[matches(@ref, 'wiki:Q\d+')][1]"/>
                    </xsl:call-template>
                    <xsl:call-template name="t_QItem">
                        <xsl:with-param name="p_input" select="replace(node()[matches(@ref, 'wiki:Q\d+')][1]/@ref, '^.*wiki:(Q\d+).*$', '$1')"/>
                    </xsl:call-template>
                </P123>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>WARNING: </xsl:text>
                    <xsl:text>publisher "</xsl:text>
                    <xsl:value-of select="tei:orgName[1]"/>
                    <xsl:text>" has not been identified in authority files.</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:pubPlace" mode="m_tei2wikidata">
        <xsl:choose>
            <xsl:when test="tei:placeName[matches(@ref, 'wiki:Q\d+|geon:\d+')]">
                <xsl:variable name="v_placeName" select="oape:query-gazetteer(tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'tei-ref', '')"/>
                <P291>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="tei:placeName[matches(@ref, 'wiki:Q\d+|geon:\d+')][1]"/>
                    </xsl:call-template>
                    <xsl:call-template name="t_string-value">
                        <xsl:with-param name="p_input" select="oape:query-gazetteer(tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'name', '')"/>
                    </xsl:call-template>
                    <xsl:choose>
                        <!-- linked to Wikidata -->
                        <xsl:when test="$v_placeName[matches(., 'wiki:Q\d+')]">
                            <xsl:call-template name="t_QItem">
                                <xsl:with-param name="p_input" select="replace($v_placeName, '^.*wiki:(Q\d+).*$', '$1')"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- linked to Geonames -->
                        <xsl:when test="$v_placeName[matches(., 'geon:\d+')]">
                            <P1566>
                                <xsl:value-of select="replace($v_placeName, '^.*geon:(\d+).*$', '$1')"/>
                            </P1566>
                        </xsl:when>
                    </xsl:choose>
                </P291>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Unidentified place of publication: </xsl:text>
                    <xsl:value-of select="tei:placeName[1]"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:textLang" mode="m_tei2wikidata">
        <P407>
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:for-each select="tokenize(@mainLang, '\s')">
                <xsl:choose>
                    <xsl:when test="oape:string-convert-lang-codes(., 'bcp47', 'wikidata') != 'NA'">
                        <QItem>
                            <xsl:value-of select="oape:string-convert-lang-codes(., 'bcp47', 'wikidata')"/>
                        </QItem>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="t_reconcile-lang">
                            <xsl:with-param name="p_lang" select="."/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </P407>
    </xsl:template>
    <!-- this template is currently unused and not necessary -->
    <xsl:template name="t_reconcile-lang">
        <xsl:param name="p_lang"/>
        <P219>
            <xsl:value-of select="oape:string-convert-lang-codes($p_lang, 'bcp47', 'iso639-2')"/>
        </P219>
    </xsl:template>
    <xsl:template match="tei:title" mode="m_tei2wikidata">
        <P1476>
            <xsl:apply-templates mode="m_string" select="."/>
            <!-- add qualifier for transcriptions? Problem: we have no explicit linking between an Arabic string and its various transcriptions  -->
            <xsl:if test="@xml:lang = 'ar' and parent::node()/tei:title[not(@type)]/@xml:lang = 'ar-Latn-x-ijmes'">
                <xsl:for-each-group group-by="lower-case(.)" select="parent::node()/tei:title[not(@type)][@xml:lang = 'ar-Latn-x-ijmes']">
                    <P8991>
                        <string>
                            <xsl:apply-templates mode="m_plain-text" select="current-grouping-key()"/>
                        </string>
                    </P8991>
                </xsl:for-each-group>
            </xsl:if>
        </P1476>
    </xsl:template>
    <!-- in consequence I should exclude all transcribed titles -->
    <xsl:template match="tei:title[not(@type)][@xml:lang = 'ar-Latn-x-ijmes'][parent::node()/tei:title[not(@type)][@xml:lang = 'ar']]"/>
    <xsl:template match="tei:title[@type = 'sub']" mode="m_tei2wikidata">
        <P1680>
            <xsl:apply-templates mode="m_string" select="."/>
        </P1680>
    </xsl:template>
    <xsl:template match="tei:title[@type = 'alt']"/>
    <xsl:template match="@oape:frequency" mode="m_tei2wikidata">
        <P2896>
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <!-- this needs further converting into "amount" and "unit", i.e. "weekly" into 1 week -->
            <xsl:choose>
                <xsl:when test=". = 'annually'">
                    <amount>1</amount>
                    <unit>year</unit>
                </xsl:when>
                <xsl:when test=". = 'annually'">
                    <amount>2</amount>
                    <unit>year</unit>
                </xsl:when>
                <xsl:when test=". = 'biweekly'">
                    <amount>2</amount>
                    <unit>week</unit>
                </xsl:when>
                <xsl:when test=". = 'daily'">
                    <amount>1</amount>
                    <unit>day</unit>
                </xsl:when>
                <xsl:when test=". = 'fortnightly'">
                    <amount>2</amount>
                    <unit>month</unit>
                </xsl:when>
                <xsl:when test=". = 'monthly'">
                    <amount>1</amount>
                    <unit>month</unit>
                </xsl:when>
                <xsl:when test=". = 'quarterly'">
                    <amount>4</amount>
                    <unit>year</unit>
                </xsl:when>
                <xsl:when test=". = 'triweekly'">
                    <amount>3</amount>
                    <unit>week</unit>
                </xsl:when>
                <xsl:when test=". = 'weekly'">
                    <amount>1</amount>
                    <unit>week</unit>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>WARNING: </xsl:text>
                        <xsl:value-of select="."/>
                        <xsl:text> cannot be converted</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </P2896>
    </xsl:template>
    <xsl:template match="@xml:lang" mode="m_tei2wikidata">
        <xsl:attribute name="xml:lang">
            <xsl:choose>
                <xsl:when test="matches(., '-Arab-')">
                    <xsl:text>ar</xsl:text>
                </xsl:when>
                <xsl:when test="matches(., '-Latn-x-ijmes|ar-Latn-EN')">
                    <xsl:text>en</xsl:text>
                </xsl:when>
                <xsl:when test="matches(., '-Latn-x-dmg|ar-Latn-DE')">
                    <xsl:text>de</xsl:text>
                </xsl:when>
                <xsl:when test="matches(., '-Latn-FR')">
                    <xsl:text>fr</xsl:text>
                </xsl:when>
                <xsl:when test="matches(., '-Latn-TR')">
                    <xsl:text>tr</xsl:text>
                </xsl:when>
                <xsl:when test="matches(., '-Latn')">
                    <xsl:text>en</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="tei:person" mode="m_tei2wikidata">
        <xsl:variable name="v_id-wiki" select="descendant::tei:idno[@type = 'wiki'][1]"/>
        <xsl:variable name="v_id-viaf" select="descendant::tei:idno[@type = 'VIAF'][1]"/>
        <item>
            <xsl:choose>
                <xsl:when test="descendant::tei:idno[@type = 'wiki']">
                    <xsl:attribute name="xml:id" select="descendant::tei:idno[@type = 'wiki'][1]"/>
                </xsl:when>
                <xsl:when test="descendant::tei:idno[@type = $p_local-authority]">
                    <xsl:attribute name="xml:id" select="concat($p_local-authority, '_', descendant::tei:idno[@type = $p_local-authority][1])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="xml:id" select="concat('temp_', generate-id(.))"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- add label and description -->
            <label xml:lang="en">
                <xsl:value-of select="oape:query-person(., 'name', 'en', $p_local-authority)"/>
            </label>
            <label xml:lang="ar">
                <xsl:value-of select="oape:query-person(., 'name', 'ar', $p_local-authority)"/>
            </label>
            <!-- descriptions have a maximum length, that is easily breached by multiple entries hier. -->
            <xsl:variable name="v_first-title" select="tei:occupation[descendant::tei:title[@level = 'j']][1]/descendant::tei:title[@level = 'j'][1]"/>
            <description xml:lang="en">
                <xsl:text>Editor of </xsl:text>
                <xsl:text>"</xsl:text>
                <xsl:value-of select="oape:query-bibliography($v_first-title, $v_bibliography, $v_gazetteer, $p_local-authority, 'title', 'Latn')"/>
                <xsl:text>" published in </xsl:text>
                <xsl:value-of select="oape:query-bibliography($v_first-title, $v_bibliography, $v_gazetteer, $p_local-authority, 'pubPlace', 'en')"/>
                <!-- <xsl:for-each select="tei:occupation/descendant::tei:title[@level = 'j']">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="oape:query-bibliography(., $v_bibliography, $v_gazetteer, $p_local-authority, 'title', 'Latn')"/>
                    <xsl:text>" published in </xsl:text>
                    <xsl:value-of select="oape:query-bibliography(., $v_bibliography, $v_gazetteer, $p_local-authority, 'pubPlace', 'en')"/>
                    <xsl:if test="ancestor::tei:occupation[1]/following-sibling::tei:occupation[descendant::tei:title]">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>-->
            </description>
            <description xml:lang="ar">
                <xsl:text>محرر لدورية </xsl:text>
                <xsl:text>"</xsl:text>
                <xsl:value-of select="oape:query-bibliography($v_first-title, $v_bibliography, $v_gazetteer, $p_local-authority, 'title', 'ar')"/>
                <xsl:text>" تصدر في </xsl:text>
                <xsl:value-of select="oape:query-bibliography($v_first-title, $v_bibliography, $v_gazetteer, $p_local-authority, 'pubPlace', 'ar')"/>
                <!--<xsl:for-each select="tei:occupation/descendant::tei:title[@level = 'j']">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="oape:query-bibliography(., $v_bibliography, $v_gazetteer, $p_local-authority, 'title', 'ar')"/>
                    <xsl:text>" تصدر في </xsl:text>
                    <xsl:value-of select="oape:query-bibliography(., $v_bibliography, $v_gazetteer, $p_local-authority, 'pubPlace', 'ar')"/>
                    <xsl:if test="ancestor::tei:occupation[1]/following-sibling::tei:occupation[descendant::tei:title]">
                        <xsl:text> و</xsl:text>
                    </xsl:if>
                </xsl:for-each>-->
            </description>
            <!-- instance of: human -->
            <P31>Q5</P31>
            <!-- names -->
            <xsl:apply-templates mode="m_tei2wikidata" select="oape:query-person(., 'name-tei', 'ar', $p_local-authority)"/>
            <xsl:apply-templates mode="m_tei2wikidata" select="oape:query-person(., 'name-tei', 'en', $p_local-authority)"/>
            <!-- languages -->
            <xsl:for-each select="tei:occupation/descendant::tei:title[@level = 'j']">
                <xsl:variable name="v_langs">
                    <xsl:copy-of select="oape:query-bibliography(., $v_bibliography, $v_gazetteer, $p_local-authority, 'langs', '')"/>
                </xsl:variable>
                <xsl:variable name="v_id-wiki" select="oape:query-bibliography(., $v_bibliography, $v_gazetteer, $p_local-authority, 'id-wiki', '')"/>
                <xsl:for-each select="$v_langs/tei:lang">
                    <!-- language spoken, written etc. -->
                    <P1412>
                        <QItem>
                            <xsl:value-of select="oape:string-convert-lang-codes(., 'bcp47', 'wikidata')"/>
                        </QItem>
                        <!-- inferred from -->
                        <xsl:if test="$v_id-wiki != 'NA'">
                            <P3452>
                                <QItem>
                                    <xsl:value-of select="$v_id-wiki"/>
                                </QItem>
                            </P3452>
                        </xsl:if>
                    </P1412>
                </xsl:for-each>
            </xsl:for-each>
            <!-- life dates -->
            <!-- identifiers -->
            <xsl:apply-templates mode="m_tei2wikidata" select="tei:idno"/>
            <!-- occupation -->
            <xsl:apply-templates mode="m_tei2wikidata" select="tei:occupation"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:persName" mode="m_tei2wikidata">
        <P2561>
            <xsl:apply-templates mode="m_tei2wikidata" select="@xml:lang"/>
            <xsl:apply-templates mode="m_string" select="."/>
        </P2561>
    </xsl:template>
    <xsl:template match="tei:occupation" mode="m_tei2wikidata"/>
    <xsl:template match="tei:occupation[descendant::tei:bibl | descendant::tei:title]" mode="m_tei2wikidata">
        <xsl:variable name="v_id-wiki-title" select="oape:query-bibliography(descendant::tei:title[@level = 'j'][1], $v_bibliography, $v_gazetteer, $p_local-authority, 'id-wiki', '')"/>
        <!-- journal editor -->
        <P106>
            <!-- this produces far too many sources (due to how @source on occupation came about) -->
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <QItem>Q124634459</QItem>
            <!-- qualifier: employer. Note that this is more of a work-around -->
            <xsl:if test="$v_id-wiki-title != 'NA'">
                <P108>
                    <xsl:value-of select="$v_id-wiki-title"/>
                </P108>
            </xsl:if>
        </P106>
        <!-- journalist  -->
        <P106>
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <QItem>Q1930187</QItem>
        </P106>
        <!-- location of work -->
    </xsl:template>
    <!-- holdings -->
    <xsl:template match="tei:note[@type = 'holdings']" mode="m_tei2wikidata_holdings">
        <!-- all holdings -->
        <xsl:apply-templates mode="m_tei2wikidata" select="tei:list/tei:item"/>
        <!-- all digitised copies -->
        <xsl:apply-templates mode="m_tei2wikidata" select="descendant::tei:idno[@subtype = 'self']"/>
    </xsl:template>
    <xsl:template match="tei:item[parent::tei:list/parent::tei:note[@type = 'holdings']][tei:label/tei:orgName]" mode="m_tei2wikidata">
        <!-- get all refs -->
        <xsl:variable name="v_refs" select="oape:query-organizationography(tei:label/tei:orgName, $v_organizationography, $p_local-authority, 'tei-ref', '')"/>
        <!-- collection -->
        <P195>
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <string>
                <xsl:value-of select="oape:query-organizationography(tei:label/tei:orgName, $v_organizationography, $p_local-authority, 'name', 'en')"/>
            </string>
            <xsl:choose>
                <xsl:when test="matches($v_refs, concat($p_acronym-wikidata, ':'))">
                    <QItem>
                        <xsl:value-of select="oape:query-organizationography(tei:label/tei:orgName, $v_organizationography, $p_local-authority, 'id-wiki', '')"/>
                    </QItem>
                </xsl:when>
                <xsl:when test="matches($v_refs, 'isil:')">
                    <!-- ISIL codes are part recorded in P791 -->
                    <P791>
                        <xsl:value-of select="oape:query-organizationography(tei:label/tei:orgName, $v_organizationography, $p_local-authority, 'id-isil', '')"/>
                    </P791>
                </xsl:when>
                <xsl:when test="matches($v_refs, 'viaf:')">
                    <P214>
                        <xsl:value-of select="oape:query-organizationography(tei:label/tei:orgName, $v_organizationography, $p_local-authority, 'id-viaf', '')"/>
                    </P214>
                </xsl:when>
            </xsl:choose>
            <!-- aggregate data on the entire collection: note that there is a "single best value" constraint on this 
            - P580: start time 
            - P582: end time -->
            <xsl:if test="descendant::tei:date[@type = 'onset']">
                <xsl:variable name="v_onset">
                    <tei:date type="onset">
                        <xsl:copy-of select="@source"/>
                        <xsl:attribute name="when" select="oape:dates-get-maxima(descendant::tei:date[@type = 'onset'], 'onset')"/>
                    </tei:date>
                </xsl:variable>
                <xsl:apply-templates mode="m_tei2wikidata_holdings" select="$v_onset/tei:date"/>
            </xsl:if>
            <xsl:if test="descendant::tei:date[@type = 'terminus']">
                <xsl:variable name="v_terminus">
                    <tei:date type="terminus">
                        <xsl:copy-of select="@source"/>
                        <xsl:attribute name="when" select="oape:dates-get-maxima(descendant::tei:date[@type = 'terminus'], 'terminus')"/>
                    </tei:date>
                </xsl:variable>
                <xsl:apply-templates mode="m_tei2wikidata_holdings" select="$v_terminus/tei:date"/>
            </xsl:if>
            <!-- P478: volume -->
            <xsl:if test="descendant::tei:bibl/tei:biblScope[@unit = 'volume']">
                <P478>
                    <xsl:value-of select="min(descendant::tei:bibl/tei:biblScope[@unit = 'volume']/@from)"/>
                    <xsl:if test="min(descendant::tei:bibl/tei:biblScope[@unit = 'volume']/@from) lt max(descendant::tei:bibl/tei:biblScope[@unit = 'volume']/@to)">
                        <xsl:text>-</xsl:text>
                        <xsl:value-of select="max(descendant::tei:bibl/tei:biblScope[@unit = 'volume']/@to)"/>
                    </xsl:if>
                </P478>
            </xsl:if>
            <!-- P217: inventory number -->
            <xsl:apply-templates mode="m_tei2wikidata_qualifier" select="descendant::tei:bibl/tei:idno[@type = 'classmark']"/>
            <!-- full work available at URL -->
            <xsl:apply-templates mode="m_tei2wikidata_qualifier" select="descendant::tei:bibl/tei:idno[@type = ('URI', 'url')][@subtype = 'self']"/>
            <xsl:apply-templates mode="m_tei2wikidata_qualifier" select="descendant::tei:bibl/tei:idno[@type = ('ARK', 'HDL', 'hdl')]"/>
        </P195>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'classmark']" mode="m_tei2wikidata_qualifier">
        <P217>
            <xsl:apply-templates mode="m_string" select="."/>
        </P217>
    </xsl:template>
    <xsl:template match="tei:idno[@type = ('URI', 'url')][@subtype = 'self']" mode="m_tei2wikidata_qualifier">
        <!-- full work available at URL -->
        <P953>
            <xsl:apply-templates mode="m_string" select="."/>
        </P953>
        <!-- catch Handle.net -->
        <xsl:choose>
            <xsl:when test="matches(., '^https*://hdl\.')">
                <P1184>
                    <xsl:value-of select="replace(., '^https*://hdl\.[^/]+/(.+)$', '$1')"/>
                </P1184>
            </xsl:when>
            <xsl:otherwise>
                <!-- full work available at URL -->
                <!--<P953>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P953>-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- archival resource key -->
    <xsl:template match="tei:idno[@type = ('ARK')]" mode="m_tei2wikidata_qualifier">
        <P8091>
            <xsl:apply-templates mode="m_string" select="."/>
        </P8091>
    </xsl:template>
    <!-- Handle ID -->
    <xsl:template match="tei:idno[@type = ('hdl', 'HDL')]" mode="m_tei2wikidata_qualifier">
        <P1184>
            <xsl:apply-templates mode="m_string" select="."/>
        </P1184>
    </xsl:template>
    <xsl:template match="tei:idno[@type = ('URI', 'url')][@subtype = 'self']" mode="m_tei2wikidata">
        <!-- full work available at URL -->
        <P953>
            <xsl:apply-templates mode="m_string" select="."/>
            <!-- add qualifiers -->
            <!-- P577: publication date -->
            <!-- P478: volume -->
            <xsl:if test="ancestor::tei:bibl[1]/tei:biblScope[@unit = 'volume']">
                <P478/>
            </xsl:if>
            <!-- date of retrieval: I do not track this date in my data -->
        </P953>
    </xsl:template>
    <!-- organizations -->
    <xsl:template match="tei:org" mode="m_tei2wikidata">
        <xsl:variable name="v_id-wiki" select="descendant::tei:idno[@type = 'wiki'][1]"/>
        <xsl:variable name="v_id-isil" select="descendant::tei:idno[@type = 'isil'][1]"/>
        <item>
            <xsl:choose>
                <xsl:when test="descendant::tei:idno[@type = 'wiki']">
                    <xsl:attribute name="xml:id" select="descendant::tei:idno[@type = 'wiki'][1]"/>
                </xsl:when>
                <xsl:when test="descendant::tei:idno[@type = $p_local-authority]">
                    <xsl:attribute name="xml:id" select="concat($p_local-authority, '_', descendant::tei:idno[@type = $p_local-authority][1])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="xml:id" select="concat('temp_', generate-id(.))"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- add label and description -->
            <label xml:lang="en">
                <xsl:value-of select="oape:query-org(., 'name', 'en', $p_local-authority)"/>
            </label>
            <!-- native label -->
            <xsl:for-each select="tei:orgName[not(@type = 'short')][@xml:lang != 'en']">
                <label xml:lang="{@xml:lang}">
                    <xsl:value-of select="."/>
                </label>
            </xsl:for-each>
            <!-- I commonly do not have Arabic labels -->
            <!--<label xml:lang="ar">
                <xsl:value-of select="oape:query-org(., 'name', 'ar', $p_local-authority)"/>
            </label>-->
            <description xml:lang="en">
                <xsl:choose>
                    <xsl:when test="@type = 'library'">
                        <xsl:text>Library</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'university'">
                        <xsl:text>University</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'archive'">
                        <xsl:text>Archive</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'researchInstitute'">
                        <xsl:text>Research institute</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'museum'">
                        <xsl:text>Museum</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>Institution</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="oape:query-org(., 'location-name', 'en', $p_local-authority) != 'NA'">
                    <xsl:text> in </xsl:text>
                    <xsl:value-of select="oape:query-org(., 'location-name', 'en', $p_local-authority)"/>
                </xsl:if>
            </description>
            <description xml:lang="ar">
                <xsl:choose>
                    <xsl:when test="@type = 'library'">
                        <xsl:text>مكتبة</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'university'">
                        <xsl:text>جامعة</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'archive'">
                        <xsl:text>ارشيف</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'researchInstitute'">
                        <xsl:text>معهد الأبحاث</xsl:text>
                    </xsl:when>
                    <xsl:when test="@type = 'museum'">
                        <xsl:text>متحف</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="oape:query-org(., 'location-name', 'en', $p_local-authority) != 'NA'">
                    <xsl:text>  في </xsl:text>
                    <xsl:value-of select="oape:query-org(., 'location-name', 'ar', $p_local-authority)"/>
                </xsl:if>
            </description>
            <!-- instance of: depends on @type attribute -->
            <P31>
                <xsl:call-template name="t_source">
                    <xsl:with-param name="p_input" select="."/>
                </xsl:call-template>
                <xsl:choose>
                    <xsl:when test="@type = 'library'">
                        <QItem>Q7075</QItem>
                    </xsl:when>
                    <xsl:when test="@type = 'university'">
                        <QItem>Q3918</QItem>
                    </xsl:when>
                    <xsl:when test="@type = 'archive'">
                        <QItem>Q166118</QItem>
                    </xsl:when>
                    <xsl:when test="@type = 'digitalLibrary'">
                        <QItem>Q212805</QItem>
                    </xsl:when>
                    <xsl:when test="@type = 'researchInstitute'">
                        <QItem>Q31855</QItem>
                    </xsl:when>
                    <xsl:when test="@type = 'museum'">
                        <QItem>Q33506</QItem>
                    </xsl:when>
                    <xsl:when test="@type">
                        <string>
                            <xsl:value-of select="@type"/>
                        </string>
                    </xsl:when>
                </xsl:choose>
            </P31>
            <!-- names -->
            <xsl:apply-templates mode="m_tei2wikidata" select="oape:query-org(., 'name-tei', 'ar', $p_local-authority)"/>
            <xsl:apply-templates mode="m_tei2wikidata" select="oape:query-org(., 'name-tei', 'en', $p_local-authority)"/>
            <!-- location -->
            <xsl:apply-templates mode="m_tei2wikidata" select="tei:location"/>
            <!-- identifiers -->
            <xsl:apply-templates mode="m_tei2wikidata" select="tei:idno"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:orgName" mode="m_tei2wikidata"/>
    <xsl:template match="tei:location" mode="m_tei2wikidata">
        <xsl:apply-templates mode="m_tei2wikidata" select="tei:geo"/>
        <xsl:apply-templates mode="m_tei2wikidata" select="tei:address"/>
        <xsl:apply-templates mode="m_tei2wikidata" select="tei:address/tei:postCode"/>
        <xsl:apply-templates mode="m_tei2wikidata" select="descendant::tei:placeName"/>
    </xsl:template>
    <xsl:template match="tei:placeName" mode="m_tei2wikidata">
        <P276>
            <!-- string and source -->
            <xsl:apply-templates mode="m_string" select="."/>
            <!-- identifiers -->
            <xsl:if test="@ref">
                <xsl:if test="oape:query-gazetteer(., $v_gazetteer, $p_local-authority, 'id-wiki', '') != 'NA'">
                    <xsl:call-template name="t_QItem">
                        <xsl:with-param name="p_input" select="oape:query-gazetteer(., $v_gazetteer, $p_local-authority, 'id-wiki', '')"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:if test="oape:query-gazetteer(., $v_gazetteer, $p_local-authority, 'id-geon', '') != 'NA'">
                    <P1566>
                        <xsl:value-of select="oape:query-gazetteer(., $v_gazetteer, $p_local-authority, 'id-geon', '')"/>
                    </P1566>
                </xsl:if>
            </xsl:if>
        </P276>
    </xsl:template>
    <xsl:template match="tei:geo" mode="m_tei2wikidata">
        <P625>
            <xsl:apply-templates mode="m_string" select="."/>
        </P625>
    </xsl:template>
    <xsl:template match="tei:address" mode="m_tei2wikidata">
        <P6375>
            <xsl:if test="tei:street">
                <xsl:value-of select="concat(tei:street, ', ')"/>
            </xsl:if>
            <xsl:if test="tei:postCode">
                <xsl:value-of select="concat(tei:postCode, ' ')"/>
            </xsl:if>
            <xsl:if test="tei:placeName">
                <xsl:value-of select="tei:placeName"/>
            </xsl:if>
        </P6375>
    </xsl:template>
    <xsl:template match="tei:postCode" mode="m_tei2wikidata">
        <P281>
            <xsl:apply-templates mode="m_string" select="."/>
        </P281>
    </xsl:template>
    <xsl:template match="@next | @prev" mode="m_tei2wikidata">
        <xsl:variable name="v_property">
            <xsl:choose>
                <xsl:when test="name(.) = 'prev'">
                    <xsl:text>P1365</xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'next'">
                    <xsl:text>P1366</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_title-temp">
            <tei:title ref="{.}"/>
        </xsl:variable>
        <xsl:variable name="v_id-wiki" select="oape:query-bibliography($v_title-temp/tei:title, $v_bibliography, $v_gazetteer, $p_local-authority, 'id-wiki', '')"/>
        <!-- replaced by -->
        <xsl:element name="{$v_property}">
            <xsl:choose>
                <xsl:when test="$v_id-wiki != 'NA'">
                    <xsl:call-template name="t_QItem">
                        <xsl:with-param name="p_input" select="$v_id-wiki"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- title -->
                    <xsl:apply-templates mode="m_tei2wikidata" select="oape:query-bibliography($v_title-temp/tei:title, $v_bibliography, $v_gazetteer, $p_local-authority, 'title-tei', '')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    <xsl:template match="@* | node()" mode="m_string">
        <xsl:call-template name="t_source">
            <xsl:with-param name="p_input" select="."/>
        </xsl:call-template>
        <xsl:call-template name="t_string-value">
            <xsl:with-param name="p_input" select="."/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
