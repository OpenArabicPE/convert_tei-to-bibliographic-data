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
    <xsl:template match="element()[not(attribute())][not(text())][not(element())]" priority="2"/>
    <!--  remove attributes  -->
    <xsl:template match="@xml:id | tei:monogr/@xml:lang | tei:title/@level | tei:title/@ref"/>
    <!-- remove nodes -->
    <xsl:template match="tei:date[@type = 'documented']"/>
    <!-- convert textual content to a string node -->
    <xsl:template name="t_string-value">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_text">
            <xsl:for-each select="$p_input/descendant-or-self::text()">
                <xsl:value-of select="concat(' ', ., ' ')"/>
            </xsl:for-each>
        </xsl:variable>
        <string>
            <xsl:apply-templates select="$p_input/@xml:lang"/>
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
                    <P854>
                        <xsl:choose>
                            <xsl:when test="matches($v_source, 'oclc_618896732/|oclc_165855925/')">
                                <xsl:value-of select="replace($v_source, '^(\.\./)+TEI/', 'https://tillgrallert.github.io/')"/>
                            </xsl:when>
                            <xsl:when test="matches($v_source, '/OpenArabicPE/')">
                                <xsl:value-of select="replace($v_source, '^^(\.\./)+OpenArabicPE/', 'https://openarabicpe.github.io/')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>WARNING: </xsl:text>
                                    <xsl:value-of select="$v_source"/>
                                    <xsl:text> could not be resolved</xsl:text>
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </P854>
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
    <xsl:template match="tei:biblScope"/>
    <xsl:template match="tei:biblStruct">
        <item>
            <xsl:choose>
                <xsl:when test="descendant::tei:idno[@type = 'wiki']">
                    <xsl:attribute name="xml:id" select="descendant::tei:idno[@type = 'wiki'][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="xml:id" select="concat($p_local-authority, '_', descendant::tei:idno[@type = $p_local-authority][1])"/>
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
                    <xsl:when test="@type = 'periodical'">
                        <xsl:value-of select="@type"/>
                    </xsl:when>
                </xsl:choose>
                <xsl:text> published in </xsl:text>
                <xsl:value-of select="oape:query-biblstruct(., 'pubPlace', 'en', $v_gazetteer, $p_local-authority)"/>
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
                    <xsl:when test="@type = 'periodical'">
                        <xsl:text>دورية</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:text> تصدر في </xsl:text>
                <xsl:value-of select="oape:query-biblstruct(., 'pubPlace', 'ar', $v_gazetteer, $p_local-authority)"/>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$v_onset != 'NA' and $v_terminus != 'NA'">
                        <xsl:text>بين سنة </xsl:text>
                        <xsl:value-of select="$v_onset"/>
                        <xsl:text> و </xsl:text>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:when>
                    <xsl:when test="$v_onset != 'NA' and $v_terminus = 'NA'">
                        <xsl:text>من سنة </xsl:text>
                        <xsl:value-of select="$v_onset"/>
                    </xsl:when>
                    <xsl:when test="$v_onset = 'NA' and $v_terminus != 'NA'">
                        <xsl:text>حتى سنة </xsl:text>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:when>
                </xsl:choose>
            </description>
            <xsl:apply-templates select="@oape:frequency | @type | @subtype | node()"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:biblStruct/@subtype | tei:biblStruct/@type">
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
    <xsl:template match="tei:date[@type = 'onset']">
        <P571>
            <xsl:apply-templates mode="m_date-when" select="."/>
            <!-- notBefore: currently there is no property for earlies start date -->
            <!-- notAfter: P8555, latest start date -->
            <xsl:if test="@notAfter">
                <P8555>
                    <date>
                        <xsl:value-of select="@notAfter"/>
                    </date>
                </P8555>
            </xsl:if>
        </P571>
        <!-- start time -->
        <P580>
            <xsl:apply-templates mode="m_date-when" select="."/>
        </P580>
    </xsl:template>
    <xsl:template match="tei:date[@type = 'terminus']">
        <!-- end time -->
        <P582>
            <xsl:apply-templates mode="m_date-when" select="."/>
            <!-- notBefore: P8554, earliest end date -->
            <xsl:if test="@notBefore">
                <P8554>
                    <date>
                        <xsl:value-of select="@notBefore"/>
                    </date>
                </P8554>
            </xsl:if>
            <!-- notAfter: P12506, latest end date -->
            <xsl:if test="@notAfter">
                <P12506>
                    <date>
                        <xsl:value-of select="@notAfter"/>
                    </date>
                </P12506>
            </xsl:if>
        </P582>
    </xsl:template>
    <xsl:template match="tei:date[ancestor::tei:biblStruct][1]/tei:monogr/tei:title[@level = 'm']">
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
    </xsl:template>
    <xsl:template match="tei:editor[tei:orgName]"/>
    <xsl:template match="tei:editor[tei:persName]">
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
    <xsl:template match="tei:persName[tei:editor]" mode="m_name-string">
        <P2093>
            <xsl:apply-templates mode="m_string" select="."/>
        </P2093>
    </xsl:template>
    <xsl:template match="tei:idno">
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
            <xsl:when test="@type = 'ISSN'">
                <P236>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P236>
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
            <xsl:when test="@type = 'jid'">
                <P953>
                    <xsl:apply-templates mode="m_string" select="concat($p_url-resolve-jid, .)"/>
                </P953>
            </xsl:when>
            <xsl:when test="@type = 'shamela'">
                <P953>
                    <xsl:apply-templates mode="m_string" select="concat($p_url-resolve-shamela, .)"/>
                </P953>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>WARNING: idno of type "</xsl:text>
                    <xsl:value-of select="@type"/>
                    <xsl:text>" is not converted</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:imprint">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:monogr">
        <xsl:apply-templates select="@oape:frequency | node()"/>
    </xsl:template>
    <xsl:template match="tei:monogr[@type = 'reprint']"/>
    <xsl:template match="tei:publisher">
        <!-- converting to a reconciled Wikidata item! -->
        <xsl:choose>
            <xsl:when test="node()[matches(@ref, 'wiki:Q\d+')]">
                <P123>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="node()[matches(@ref, 'wiki:Q\d+')]"/>
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
    <xsl:template match="tei:pubPlace">
        <xsl:choose>
            <xsl:when test="tei:placeName[matches(@ref, 'wiki:Q\d+|geon:\d+')]">
                <P291>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="tei:placeName[matches(@ref, 'wiki:Q\d+|geon:\d+')]"/>
                    </xsl:call-template>
                    <xsl:choose>
                        <!-- linked to Wikidata -->
                        <xsl:when test="tei:placeName[matches(@ref, 'wiki:Q\d+')]">
                            <xsl:call-template name="t_QItem">
                                <xsl:with-param name="p_input" select="replace(tei:placeName[matches(@ref, 'wiki:Q\d+')][1]/@ref, '^.*wiki:(Q\d+).*$', '$1')"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- linked to Geonames -->
                        <xsl:when test="tei:placeName[matches(@ref, 'geon:\d+')]">
                            <xsl:call-template name="t_string-value">
                                <xsl:with-param name="p_input" select="tei:placeName[matches(@ref, 'geon:\d+')][1]"/>
                            </xsl:call-template>
                            <P1566>
                                <xsl:value-of select="replace(tei:placeName[matches(@ref, 'geon:\d+')][1]/@ref, '^.*geon:(\d+).*$', '$1')"/>
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
    <xsl:template match="tei:textLang">
        <P407>
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="oape:string-convert-lang-codes(@mainLang, 'bcp47', 'wikidata') != 'NA'">
                    <QItem>
                        <xsl:value-of select="oape:string-convert-lang-codes(@mainLang, 'bcp47', 'wikidata')"/>
                    </QItem>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="t_reconcile-lang">
                        <xsl:with-param name="p_lang" select="@mainLang"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </P407>
    </xsl:template>
    <!-- this template is currently unused and not necessary -->
    <xsl:template name="t_reconcile-lang">
        <xsl:param name="p_lang"/>
        <P219>
            <xsl:value-of select="oape:string-convert-lang-codes($p_lang, 'bcp47', 'iso639-2')"/>
        </P219>
    </xsl:template>
    <xsl:template match="tei:title">
        <P1476>
            <xsl:apply-templates mode="m_string" select="."/>
        </P1476>
    </xsl:template>
    <xsl:template match="tei:title[@type = 'sub']">
        <P1680>
            <xsl:apply-templates mode="m_string" select="."/>
        </P1680>
    </xsl:template>
    <xsl:template match="@oape:frequency">
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
    <xsl:template match="@xml:lang">
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
    <xsl:template match="tei:person">
        <xsl:variable name="v_id-wiki" select="descendant::tei:idno[@type = 'wiki'][1]"/>
        <xsl:variable name="v_id-viaf" select="descendant::tei:idno[@type = 'VIAF'][1]"/>
        <item>
            <xsl:choose>
                <xsl:when test="descendant::tei:idno[@type = 'wiki']">
                    <xsl:attribute name="xml:id" select="descendant::tei:idno[@type = 'wiki'][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="xml:id" select="concat($p_local-authority, '_', descendant::tei:idno[@type = $p_local-authority][1])"/>
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
            <xsl:apply-templates select="oape:query-person(., 'name-tei', 'ar', $p_local-authority)"/>
            <!-- life dates -->
            <!-- identifiers -->
            <xsl:apply-templates select="tei:idno"/>
            <!-- occupation -->
            <xsl:apply-templates select="tei:occupation"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:persName">
        <P2561>
            <xsl:apply-templates select="@xml:lang"/>
            <xsl:apply-templates mode="m_string" select="."/>
        </P2561>
    </xsl:template>
    <xsl:template match="tei:occupation[descendant::tei:bibl |  descendant::tei:title]">
        <xsl:variable name="v_id-wiki-title" select="oape:query-bibliography(descendant::tei:title[@level = 'j'][1], $v_bibliography, $v_gazetteer, $p_local-authority, 'id-wiki', '')"/>
        <!-- journal editor -->
        <P106>
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
    <xsl:template match="@* | node()" mode="m_string">
        <xsl:call-template name="t_source">
            <xsl:with-param name="p_input" select="."/>
        </xsl:call-template>
        <xsl:call-template name="t_string-value">
            <xsl:with-param name="p_input" select="."/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
