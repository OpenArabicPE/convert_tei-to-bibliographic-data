<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="../../../OpenArabicPE/authority-files/xslt/functions.xsl"/>
    <xsl:import href="functions.xsl"/>
    <!--    <xsl:import href="convert_marc-xml-to-tei_functions.xsl"/>-->
    <xsl:param name="p_source" select="'oape:org:31'"/>
    <xsl:variable name="v_alphabet-arabic" select="'اأإبتثحخجدذرزسشصضطظعغفقكلمنهوؤيئىةء٠١٢٣٤٥٦٧٨٩'"/>
    <xsl:variable name="v_alphabet-latin" select="'0123456789abcdefghijklmnopqrstuvwxyz'"/>
    <xsl:variable name="v_alphabet-arabic-ijmes" select="'āīūḍġḥṣṭʼʿʾ'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <xsl:template match="/" priority="20">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- identity transform -->
    <xsl:template match="node()" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- translate Arabic digits in attributes to Latin digits -->
    <xsl:template match="@*" mode="m_post-process" priority="20">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="oape:transpose-digits(., 'arabic', 'western')"/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="@*[. = '']" mode="m_post-process" priority="20"/>
    <!-- remove @source from non-sensicle places -->
    <xsl:template match="tei:monogr/@source | tei:imprint/@source" mode="m_off" priority="10"/>
    <!-- this is expensive: Unicode normalization -->
    <xsl:template match="text()" mode="m_post-process" priority="20">
        <xsl:value-of select="normalize-space(normalize-unicode(., 'NFKC'))"/>
    </xsl:template>
    <!-- the sorting instruction is expensive  -->
    <xsl:template match="tei:listBibl" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:apply-templates select="tei:biblStruct">
                <xsl:sort select="tei:monogr/tei:title[1]"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="tei:bibl"/>
        </xsl:copy>
    </xsl:template>
    <!-- add explicit bibl for holdings -->
    <xsl:template match="tei:listBibl[ancestor::tei:note[@type = 'holdings']]" mode="m_post-process" priority="20">
        <xsl:variable name="v_bibls">
            <xsl:apply-templates mode="m_identity-transform" select="tei:bibl[not(@type = 'holdings')]"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <bibl resp="#xslt" type="holdings">
                <!-- IDs -->
                <xsl:apply-templates mode="m_identity-transform" select="ancestor::tei:biblStruct/tei:monogr/tei:idno[@source = current()/@source]"/>
                <xsl:apply-templates mode="m_identity-transform" select="ancestor::tei:biblStruct/tei:monogr/tei:idno[@source = $p_source]"/>
                <xsl:for-each-group group-by="." select="$v_bibls/descendant::tei:idno[not(@type = 'URI')]">
                    <xsl:apply-templates mode="m_identity-transform" select="current-group()[1]"/>
                </xsl:for-each-group>
                <!-- URL -->
                <xsl:apply-templates mode="m_identity-transform" select="$v_bibls/descendant::tei:idno[@type = 'URI'][@subtype = 'self']"/>
                <!-- URL if HTU -->
                <xsl:if test="ancestor::tei:biblStruct[1][@source = 'oape:org:31']">
                    <xsl:apply-templates mode="m_identity-transform" select="$v_bibls/descendant::tei:idno[@type = 'URI'][matches(., '/htu/data/HTU')]"/>
                    <xsl:apply-templates mode="m_identity-transform" select="ancestor::tei:biblStruct/tei:monogr/tei:idno[@type = 'htu']"/>
                </xsl:if>
                <!-- scope -->
                <xsl:choose>
                    <!-- as issue counting usually restarts every year, it doesn't make sense to provide min and max issue numbers -->
                    <xsl:when test="$v_bibls/descendant::tei:biblScope[@unit = 'volume']">
                        <biblScope unit="volume">
                            <xsl:attribute name="from" select="min($v_bibls/descendant::tei:biblScope[@unit = 'volume']/@from)"/>
                            <xsl:attribute name="to" select="max($v_bibls/descendant::tei:biblScope[@unit = 'volume']/@to)"/>
                        </biblScope>
                    </xsl:when>
                    <xsl:when test="$v_bibls/descendant::tei:biblScope[@unit = 'issue']">
                        <biblScope unit="issue">
                            <xsl:attribute name="from" select="min($v_bibls/descendant::tei:biblScope[@unit = 'issue']/@from)"/>
                            <xsl:attribute name="to" select="max($v_bibls/descendant::tei:biblScope[@unit = 'issue']/@to)"/>
                        </biblScope>
                    </xsl:when>
                </xsl:choose>
                <!-- add dates -->
                <xsl:if test="$v_bibls/descendant::tei:date[@when, @from, @to]">
                    <date type="onset">
                        <xsl:attribute name="when" select="oape:dates-get-maxima($v_bibls/descendant::tei:date[@when, @from], 'onset')"/>
                    </date>
                    <date type="terminus">
                        <xsl:attribute name="when" select="oape:dates-get-maxima($v_bibls/descendant::tei:date[@when, @to], 'terminus')"/>
                    </date>
                </xsl:if>
            </bibl>
            <!-- reproduce the original -->
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- remove exisiting <bibl resp="#xslt" type="holdings"> -->
    <xsl:template match="tei:bibl[@type = 'holdings'][@resp = '#xslt']" mode="m_post-process" priority="20"/>
    <!-- remove trailing punctuation  -->
    <xsl:template match="text()[ancestor::tei:biblStruct][not(parent::tei:persName)]" mode="m_off" priority="10">
        <xsl:value-of select="replace(., '(\s*[,|;|:|،|؛|.]\s*)$', '')"/>
    </xsl:template>
    <!-- information to be removed as I do not further process it -->
    <xsl:template match="tei:biblStruct/@xml:lang | tei:monogr/@xml:lang | tei:imprint/@xml:lang | tei:publisher/@xml:lang | tei:pubPlace/@xml:lang | tei:idno/@xml:lang" mode="m_off"/>
    <xsl:template match="tei:biblStruct[not(@source)][ancestor::node()/@source]" mode="m_post-process" priority="1">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:copy-of select="ancestor::node()[@source][1]/@source"/>
            <xsl:apply-templates mode="m_post-process" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- remove all orgs which are already part of the organizationography -->
    <xsl:template match="tei:org[parent::tei:listOrg][tei:orgName[@ref]]" mode="m_off"/>
    <!-- establish language based on script -->
    <xsl:template match="element()[ancestor::tei:biblStruct][text()][@xml:lang = 'und' or not(@xml:lang)]" mode="m_off" priority="0">
        <xsl:variable name="v_self">
            <xsl:apply-templates mode="m_plain-text" select="text()"/>
        </xsl:variable>
        <xsl:variable name="v_self" select="normalize-space($v_self)"/>
        <xsl:variable name="v_string-test" select="substring($v_self, 4, 1)"/>
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:if test="$v_string-test != ''">
                <xsl:choose>
                    <xsl:when test="contains($v_alphabet-arabic, $v_string-test) and (ancestor::tei:biblStruct//tei:textLang/@mainLang = 'ar')">
                        <xsl:attribute name="xml:lang" select="'ar'"/>
                    </xsl:when>
                    <xsl:when test="contains($v_alphabet-arabic, $v_string-test) and (ancestor::tei:biblStruct//tei:textLang/@mainLang = 'ota')">
                        <xsl:attribute name="xml:lang" select="'ota'"/>
                    </xsl:when>
                    <xsl:when test="contains($v_alphabet-arabic, $v_string-test) and (ancestor::tei:biblStruct//tei:textLang/@mainLang = 'fa')">
                        <xsl:attribute name="xml:lang" select="'fa'"/>
                    </xsl:when>
                    <xsl:when test="matches($v_self, concat('[', $v_alphabet-arabic-ijmes, ']'))">
                        <xsl:attribute name="xml:lang" select="'ar-Latn-x-ijmes'"/>
                    </xsl:when>
                    <!-- this assumes we only deal with Arabic and Latin scripts -->
                    <xsl:otherwise>
                        <!--                        <xsl:value-of select="'und-Latn'"/>--> </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- titles -->
    <xsl:template match="tei:monogr/tei:title" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:if test="not(@level)">
                <xsl:attribute name="level" select="'j'"/>
            </xsl:if>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
        <!-- add IDs based on title -->
        <xsl:if test="@ref">
            <xsl:variable name="v_idnos" select="following-sibling::tei:idno"/>
            <xsl:for-each select="tokenize(@ref, '\s+')">
                <xsl:choose>
                    <xsl:when test="matches(., concat($p_acronym-wikidata, ':Q'))">
                        <xsl:if test="not($v_idnos/self::tei:idno[@type = $p_acronym-wikidata])">
                            <idno type="{$p_acronym-wikidata}">
                                <xsl:value-of select="substring-after(., concat($p_acronym-wikidata, ':'))"/>
                            </idno>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="matches(., concat($p_local-authority, ':bibl:'))">
                        <xsl:if test="not($v_idnos/self::tei:idno[@type = $p_local-authority])">
                            <idno type="{$p_local-authority}">
                                <xsl:value-of select="substring-after(., concat($p_local-authority, ':bibl:'))"/>
                            </idno>
                        </xsl:if>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <!-- adding subtitles -->
    <xsl:template match="tei:title[contains(., ':')]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '^(.*?)\s*:.*$', '$1')"/>
        </xsl:copy>
        <!-- add subtitle -->
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="type" select="'sub'"/>
            <xsl:value-of select="replace(., '^(.*?)\s*:\s*(.*)$', '$2')"/>
        </xsl:copy>
    </xsl:template>
    <!-- extract IDs from title attributes -->
    <xsl:template match="tei:title[@ref]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
        </xsl:copy>
        <xsl:if test="matches(@ref, concat($p_acronym-wikidata, ':Q\d+')) and not(following-sibling::tei:idno[@type = $p_acronym-wikidata])">
            <idno type="{$p_acronym-wikidata}">
                <xsl:value-of select="replace(@ref, concat('^.*', $p_acronym-wikidata, ':(Q\d+).*$'), '$1')"/>
            </idno>
        </xsl:if>
        <xsl:if test="matches(@ref, concat($p_local-authority, ':bibl:\d+')) and not(following-sibling::tei:idno[@type = $p_local-authority])">
            <idno type="{$p_local-authority}">
                <xsl:value-of select="replace(@ref, concat('^.*', $p_local-authority, ':bibl:(\d+).*$'), '$1')"/>
            </idno>
        </xsl:if>
    </xsl:template>
    <!-- identifiers -->
    <xsl:template match="tei:idno[@type = 'classmark'][starts-with(., 'b')]" mode="m_off">
        <xsl:copy>
            <xsl:attribute name="type" select="'record'"/>
            <xsl:attribute name="source" select="$p_source"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- imprint -->
    <xsl:template match="tei:publisher[not(tei:orgName)]" mode="m_off">
        <xsl:copy>
            <xsl:element name="orgName">
                <xsl:apply-templates mode="m_post-process"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:pubPlace[not(tei:placeName)]" mode="m_off">
        <xsl:copy>
            <xsl:element name="placeName">
                <xsl:apply-templates mode="m_post-process"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:imprint/tei:placeName" mode="m_off">
        <xsl:element name="pubPlace">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:imprint/text()" mode="m_off">
        <xsl:call-template name="t_test-for-dates">
            <xsl:with-param name="p_input" select="."/>
        </xsl:call-template>
        <xsl:value-of select="."/>
    </xsl:template>
    <!-- dates-->
    <xsl:template match="tei:date[matches(@when, '\d{4}-\d{1}-\d{1}$')]" mode="m_post-process" priority="12">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="when">
                <xsl:analyze-string regex="(\d{{4}}-)(\d{{1}})-(\d{{1}})$" select="@when">
                    <xsl:matching-substring>
                        <xsl:value-of select="concat(regex-group(1), '0', regex-group(2), '-0', regex-group(3))"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[matches(@when, '\d{4}-\d{1}-\d{2}')]" mode="m_post-process" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="when">
                <xsl:analyze-string regex="(\d{{4}}-)(\d{{1}})(-\d{{2}})$" select="@when">
                    <xsl:matching-substring>
                        <xsl:value-of select="concat(regex-group(1), '0', regex-group(2), regex-group(3))"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[matches(@when, '\d{4}-\d{2}-\d{1}$')]" mode="m_post-process" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="when">
                <xsl:analyze-string regex="(\d{{4}}-\d{{2}}-)(\d{{1}})$" select="@when">
                    <xsl:matching-substring>
                        <xsl:value-of select="concat(regex-group(1), '0', regex-group(2))"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- make dates machine readable -->
    <xsl:template match="tei:date" mode="m_post-process" priority="1">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@type"/>
            <xsl:choose>
                <xsl:when test="matches(@when, '^\d{4}$') and (number(@when) &lt; 1450)">
                    <xsl:attribute name="calendar" select="'#cal_islamic'"/>
                    <xsl:attribute name="datingMethod" select="'#cal_islamic'"/>
                    <xsl:attribute name="when-custom" select="@when"/>
                </xsl:when>
                <xsl:when test="matches(@when, '^\d{4}$') and (number(@when) &gt; 2050)">
                    <xsl:attribute name="calendar" select="'#cal_jewish'"/>
                    <xsl:attribute name="datingMethod" select="'#cal_jewish'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- this template only needs to run once -->
    <xsl:template match="tei:date[not(@when)][not(@calendar = '#cal_islamic')][not(@notBefore)][not(@notAfter)][not(@from)][not(@to)][not(@datingMethod)]" mode="m_post-process" priority="13">
        <xsl:variable name="v_text">
            <xsl:value-of select="descendant-or-self::text()"/>
        </xsl:variable>
        <xsl:variable name="v_text" select="normalize-space($v_text)"/>
        <xsl:choose>
            <!-- date ranges -->
            <xsl:when test="matches($v_text, '^\d{4}(هـ|هج)*\s*-\s*\d{4}(هـ|هج)*')">
                <xsl:variable name="v_onset" select="replace($v_text, '^(\d{4})(هـ|هج)*\s*-\s*(\d{4})(هـ|هج)*.*', '$1')"/>
                <xsl:variable name="v_terminus" select="replace($v_text, '^(\d{4})(هـ|هج)*\s*-\s*(\d{4})(هـ|هج)*.*', '$3')"/>
                <xsl:variable name="v_calendar-onset" select="
                        if (number($v_onset) lt $p_islamic-last-year) then
                            ('#cal_islamic')
                        else
                            ('#cal_gregorian')"/>
                <xsl:variable name="v_calendar-terminus" select="
                        if (number($v_terminus) lt $p_islamic-last-year) then
                            ('#cal_islamic')
                        else
                            ('#cal_gregorian')"/>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:choose>
                        <xsl:when test="$v_calendar-onset = '#cal_gregorian'">
                            <xsl:attribute name="when" select="$v_onset"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="datingMethod" select="$v_calendar-onset"/>
                            <xsl:attribute name="when-custom" select="$v_onset"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="type" select="'terminus'"/>
                    <xsl:choose>
                        <xsl:when test="$v_calendar-terminus = '#cal_gregorian'">
                            <xsl:attribute name="when" select="$v_terminus"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="datingMethod" select="$v_calendar-terminus"/>
                            <xsl:attribute name="when-custom" select="$v_terminus"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <!-- YYYY/YY -->
            <xsl:when test="matches($v_text, '^\d{4}/\d{2}$')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="from" select="replace($v_text, '^(\d{4})/(\d{2})$', '$1')"/>
                    <xsl:attribute name="to" select="replace($v_text, '^(\d{2})(\d{2})/(\d{2})$', '$1$3')"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <!-- YYYY/YY -->
            <xsl:when test="matches($v_text, '^\d{4}/\d{2}\s*(هـ|هج).*$')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="datingMethod" select="'#cal_islamic'"/>
                    <xsl:attribute name="from-custom" select="replace($v_text, '^(\d{4})/(\d{2}).+$', '$1')"/>
                    <xsl:attribute name="to-custom" select="replace($v_text, '^(\d{2})(\d{2})/(\d{2}).+$', '$1$3')"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <!-- ISO dates -->
            <xsl:when test="matches($v_text, '^\d{4}-\d{2}-\d{2}$')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <!--<xsl:attribute name="type" select="'onset'"/>-->
                    <xsl:attribute name="when" select="."/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <!-- DD/MM/YYYY or MM/DD/YYYY -->
            <xsl:when test="matches($v_text, '\d{2}/\d{2}/\d{4}')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <!--<xsl:attribute name="type" select="'onset'"/>-->
                    <xsl:attribute name="when" select="replace(., '^.*(\d{2})/(\d{2})/(\d{4}).*$', '$3-$2-$1')"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches($v_text, '^\d{4}-')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:attribute name="when" select="replace($v_text, '^(\d{4})\s*-.*$', '$1')"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <!-- YYYY -->
            <xsl:when test="matches($v_text, '^\d{4}$') and (number($v_text) &lt; 1450)">
                <xsl:copy>
                    <xsl:attribute name="calendar" select="'#cal_islamic'"/>
                    <xsl:attribute name="datingMethod" select="'#cal_islamic'"/>
                    <xsl:attribute name="when-custom" select="$v_text"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches($v_text, '^\d{4}$') and (number($v_text) &gt; 2050)">
                <xsl:copy>
                    <xsl:attribute name="calendar" select="'#cal_jewish'"/>
                    <xsl:attribute name="datingMethod" select="'#cal_jewish'"/>
                    <xsl:attribute name="when-custom" select="$v_text"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches($v_text, '^\d{4}$')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="when" select="replace($v_text, '^(\d{4})$', '$1')"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches($v_text, '^\d{4}\s*(هـ|هج)')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="datingMethod" select="'#cal_islamic'"/>
                    <xsl:attribute name="when-custom" select="replace($v_text, '^(\d{4}).+$', '$1')"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- add onset based on collections -->
    <xsl:template match="tei:imprint" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <!--  -->
            <xsl:apply-templates mode="m_post-process" select="tei:pubPlace"/>
            <xsl:apply-templates mode="m_post-process" select="tei:publisher"/>
            <xsl:choose>
                <!-- reproduce onsets not generated by xslt -->
                <xsl:when test="tei:date[not(@resp = '#xslt')]">
                    <xsl:apply-templates mode="m_post-process" select="tei:date[not(@resp = '#xslt')]"/>
                </xsl:when>
                <!-- generate onset based on holdings -->
                <xsl:when test="not(tei:date[@type = 'onset']) and ancestor::tei:biblStruct/tei:note[@type = 'holdings']/descendant::tei:bibl[tei:date[@type = 'onset']]">
                    <xsl:variable name="v_onset" select="oape:dates-get-maxima(ancestor::tei:biblStruct/tei:note[@type = 'holdings']/descendant::tei:bibl/tei:date[@type = 'onset'], 'onset')"/>
                    <xsl:element name="date">
                        <xsl:attribute name="type" select="'onset'"/>
                        <xsl:attribute name="resp" select="'#xslt'"/>
                        <xsl:attribute name="cert" select="'low'"/>
                        <!-- source: still missing -->
                        <xsl:attribute name="when" select="$v_onset"/>
                    </xsl:element>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:bibl[ancestor::tei:note/@type = 'holdings']" mode="m_off" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <!-- with the latest release of the TEI, @ref is available on bibl -->
            <xsl:attribute name="corresp">
                <xsl:value-of select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'tei-ref', '', '', $p_local-authority)"/>
            </xsl:attribute>
            <xsl:apply-templates mode="m_post-process" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- remove bibls for individual copies after merging -->
    <xsl:template match="tei:bibl[@type = 'copy'][parent::tei:listBibl/tei:bibl[@type = 'holdings'][not(tei:idno[@type = ('url', 'URI')])]]" mode="m_off" priority="10"/>
    <!-- [parent::tei:bibl/tei:idno[@type = 'barcode']] is only needed for USJ -->
    <xsl:template match="tei:biblScope[not(@unit)][ancestor::tei:note[@type = 'holdings']]" mode="m_off" priority="10">
        <xsl:variable name="v_content" select="normalize-space(.)"/>
        <!--<xsl:call-template name="t_test-for-dates">
            <xsl:with-param name="p_input" select="$v_content"/>
        </xsl:call-template>-->
        <!-- unfortunately, one cannot change the value of a variable as the result of an iff condition -->
        <xsl:choose>
            <!-- volume -->
            <xsl:when test="matches($v_content, '(al-Sanah|v\.|vol\.*|السنة)\s*(\d+)', 'i')">
                <xsl:variable name="v_value" select="replace($v_content, '^.*(al-Sanah|v\.|vol\.*|السنة)\s*(\d+).*$', '$2', 'i')"/>
                <xsl:copy>
                    <xsl:attribute name="unit" select="'volume'"/>
                    <xsl:attribute name="from" select="$v_value"/>
                    <xsl:attribute name="to" select="$v_value"/>
                    <xsl:apply-templates mode="m_post-process" select="@xml:lang"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
                <!--<xsl:variable name="v_content" select="replace($v_content, '^(.*)(vol\.*|السنة)\s*\d+(.*)$', '$1$3', 'i')"/>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:apply-templates mode="m_post-process" select="$v_content"/>
                </xsl:copy>-->
            </xsl:when>
            <xsl:when test="matches($v_content, '(no\.*|العدد)\s*(\d+)', 'i')">
                <xsl:variable name="v_value" select="replace($v_content, '^.*(no\.*|العدد)\s*(\d+).*$', '$2', 'i')"/>
                <xsl:copy>
                    <xsl:attribute name="unit" select="'issue'"/>
                    <xsl:attribute name="from" select="$v_value"/>
                    <xsl:attribute name="to" select="$v_value"/>
                    <xsl:apply-templates mode="m_post-process" select="@xml:lang"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
                <!--<xsl:variable name="v_content" select="replace($v_content, '^(.*)no\.*\s*\d+(.*)$', '$1$2', 'i')"/>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:apply-templates mode="m_post-process" select="$v_content"/>
                </xsl:copy>-->
            </xsl:when>
            <xsl:when test="matches($v_content, '\(\s*\d{4}\s*\)', 'i')">
                <xsl:variable name="v_value" select="replace($v_content, '^.*(\(\s*)(\d{4})(\s*\)).*$', '$2', 'i')"/>
                <xsl:element name="date">
                    <xsl:attribute name="when" select="$v_value"/>
                    <xsl:value-of select="$v_value"/>
                </xsl:element>
                <xsl:variable name="v_content" select="replace($v_content, '^(.*)\(\s*\d{4}\s*\)(.*)$', '$1$2', 'i')"/>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:apply-templates mode="m_post-process" select="$v_content"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
        <!--<xsl:choose>
            <xsl:when test="contains($v_content, '#')">
                <xsl:element name="biblScope">
                    <xsl:attribute name="unit" select="'issue'"/>
                    <xsl:value-of select="substring-after($v_content, '#')"/>
                </xsl:element>
            </xsl:when>
        </xsl:choose>-->
    </xsl:template>
    <xsl:template match="tei:biblScope[@unit][not(@from)]" mode="m_post-process" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:choose>
                <xsl:when test="matches(., '^.*\d+\s*-\s*\d+.*$')">
                    <xsl:attribute name="from" select="replace(., '^.*?(\d+)\s*-\s*(\d+).*?$', '$1')"/>
                    <xsl:attribute name="to" select="replace(., '^.*?(\d+)\s*-\s*(\d+).*?$', '$2')"/>
                </xsl:when>
                <xsl:when test="matches(., '^.*\d+.*$')">
                    <xsl:attribute name="from" select="replace(., '^.*?(\d+).*?$', '$1')"/>
                    <xsl:attribute name="to" select="replace(., '^.*?(\d+).*?$', '$1')"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- notes -->
    <xsl:template match="tei:item[ancestor::tei:note/@type = 'holdings'] | tei:listBibl[ancestor::tei:note/@type = 'holdings']" mode="m_off">
        <xsl:copy>
            <xsl:attribute name="source" select="$p_source"/>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="t_test-for-dates">
        <xsl:param name="p_input"/>
        <xsl:choose>
            <xsl:when test="matches($p_input, '\d{4}-(\d{4})*')">
                <xsl:variable name="v_onset" select="replace($p_input, '^\D*(\d{4})-(\d{4})*\D*$', '$1')"/>
                <xsl:variable name="v_terminus" select="replace($p_input, '^\D*(\d{4})-(\d{4})\D*$', '$2')"/>
                <xsl:if test="number($v_onset)">
                    <xsl:element name="date">
                        <xsl:attribute name="type" select="'onset'"/>
                        <xsl:value-of select="$v_onset"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="number($v_terminus)">
                    <xsl:element name="date">
                        <xsl:attribute name="type" select="'terminus'"/>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <xsl:when test="matches($p_input, '\d{4}')">
                <xsl:element name="date">
                    <xsl:value-of select="replace($p_input, '^\D*(\d{4})\D*$', '$1')"/>
                </xsl:element>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:persName[matches(., '[،,]')]" mode="m_off" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:element name="forename">
                <xsl:value-of select="normalize-space(replace(., '^(.+?)[،,](.+?)$', '$2'))"/>
            </xsl:element>
            <xsl:text> </xsl:text>
            <xsl:element name="surname">
                <xsl:value-of select="normalize-space(replace(., '^(.+?)[،,](.+?)$', '$1'))"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:placeName[not(contains(., ']'))][matches(., '[،,]')]" mode="m_off" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="normalize-space(replace(., '^(.+?)[،,](.+?)$', '$1'))"/>
        </xsl:copy>
        <xsl:text> </xsl:text>
        <xsl:element name="country">
            <xsl:value-of select="normalize-space(replace(., '^(.+?)[،,](.+?)$', '$2'))"/>
        </xsl:element>
    </xsl:template>
    <xsl:function name="oape:transpose-digits">
        <xsl:param name="p_input"/>
        <xsl:param name="p_from"/>
        <xsl:param name="p_to"/>
        <xsl:variable name="v_digits-arabic" select="'٠١٢٣٤٥٦٧٨٩'"/>
        <xsl:variable name="v_digits-persian" select="'٠١٢٣۴۵۶٧٨٩'"/>
        <xsl:variable name="v_digits-urdu" select="'۰۱۲۳۴۵۶۷۸۹'"/>
        <xsl:variable name="v_digits-western" select="'0123456789'"/>
        <xsl:variable name="v_from">
            <xsl:choose>
                <xsl:when test="$p_from = 'arabic'">
                    <xsl:value-of select="$v_digits-arabic"/>
                </xsl:when>
                <xsl:when test="$p_from = 'persian'">
                    <xsl:value-of select="$v_digits-persian"/>
                </xsl:when>
                <xsl:when test="$p_from = 'urdu'">
                    <xsl:value-of select="$v_digits-urdu"/>
                </xsl:when>
                <xsl:when test="$p_from = 'western'">
                    <xsl:value-of select="$v_digits-western"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        <xsl:text>Value for $p_from not available</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_to">
            <xsl:choose>
                <xsl:when test="$p_to = 'arabic'">
                    <xsl:value-of select="$v_digits-arabic"/>
                </xsl:when>
                <xsl:when test="$p_to = 'persian'">
                    <xsl:value-of select="$v_digits-persian"/>
                </xsl:when>
                <xsl:when test="$p_to = 'urdu'">
                    <xsl:value-of select="$v_digits-urdu"/>
                </xsl:when>
                <xsl:when test="$p_to = 'western'">
                    <xsl:value-of select="$v_digits-western"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        <xsl:text>Value for $p_to not available</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="translate($p_input, $v_from, $v_to)"/>
    </xsl:function>
    <xsl:template match="@oape:frequency" mode="m_off" priority="2">
        <xsl:variable name="v_canonical-values" select="'annual|annually|biweekly|daily|fortnightly|irregular|monthly|quarterly|semimonthly|semiweekly|weekly'"/>
        <xsl:variable name="v_value" select="lower-case(normalize-space(.))"/>
        <xsl:choose>
            <xsl:when test="matches($v_value, $v_canonical-values)">
                <xsl:attribute name="oape:frequency">
                    <xsl:choose>
                        <xsl:when test="$v_value = 'annual'">
                            <xsl:value-of select="'annually'"/>
                        </xsl:when>
                        <xsl:when test="$v_value = 'semiweekly'">
                            <xsl:value-of select="'biweekly'"/>
                        </xsl:when>
                        <xsl:when test="$v_value = 'semimonthly'">
                            <xsl:value-of select="'fortnightly'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$v_value"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="no">
                    <xsl:value-of select="$v_value"/>
                    <xsl:text> is not in the list of canonical values for @oape:frequency</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- remove duplicate IDs -->
    <xsl:template match="tei:idno[. = following-sibling::tei:idno[@type = current()/@type]]" mode="m_post-process"/>
</xsl:stylesheet>
