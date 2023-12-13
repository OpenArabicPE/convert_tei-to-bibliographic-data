<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="../../../OpenArabicPE/authority-files/xslt/functions.xsl"/>
    <xsl:import href="convert_marc-xml-to-tei_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:567'"/>
    <xsl:variable name="v_alphabet-arabic" select="'اأإبتثحخجدذرزسشصضطظعغفقكلمنهوؤيئىةء٠١٢٣٤٥٦٧٨٩'"/>
    <xsl:variable name="v_alphabet-latin" select="'0123456789abcdefghijklmnopqrstuvwxyz'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <xsl:template match="/" priority="20">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="node() | @*" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- this is expensive -->
    <xsl:template match="text()" mode="m_post-process" priority="2">
        <xsl:value-of select="normalize-unicode(., 'NFKC')"/>
    </xsl:template>
    <xsl:template match="text()[ancestor::tei:monogr][not(parent::tei:persName)]" mode="m_post-process" priority="10">
        <xsl:value-of select="replace(., '(\s*[,|;|:|،|؛]\s*)$', '')"/>
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
    <!-- information to be removed as I do not further process it -->
    <xsl:template match="tei:biblStruct/@xml:lang | tei:monogr/@xml:lang | tei:imprint/@xml:lang | tei:publisher/@xml:lang | tei:pubPlace/@xml:lang | tei:idno/@xml:lang" mode="m_post-process"/>
    <!-- remove all orgs which are already part of the organizationography -->
    <xsl:template match="tei:org[parent::tei:listOrg][tei:orgName[@ref]]" mode="m_off"/>
    <!-- establish language based on script -->
    <xsl:template match="element()[ancestor::tei:biblStruct][text()][@xml:lang = 'und' or not(@xml:lang)]" mode="m_off" priority="5">
        <xsl:variable name="v_string-test" select="substring(., 1, 1)"/>
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="xml:lang">
                <xsl:choose>
                    <xsl:when test="contains($v_alphabet-arabic, $v_string-test) and (ancestor::tei:biblStruct//tei:textLang/@mainLang = 'ar')">
                        <xsl:value-of select="'ar'"/>
                    </xsl:when>
                    <xsl:when test="contains($v_alphabet-arabic, $v_string-test) and (ancestor::tei:biblStruct//tei:textLang/@mainLang = 'ota')">
                        <xsl:value-of select="'ota'"/>
                    </xsl:when>
                    <xsl:when test="contains($v_alphabet-arabic, $v_string-test) and (ancestor::tei:biblStruct//tei:textLang/@mainLang = 'fa')">
                        <xsl:value-of select="'fa'"/>
                    </xsl:when>
                    <!-- this assumes we only deal with Arabic and Latin scripts -->
                    <xsl:otherwise>
                        <xsl:value-of select="'und-Latn'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
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
    </xsl:template>
    <xsl:template match="tei:title[contains(., ':')]" mode="m_post-process">
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
    <xsl:template match="tei:date" mode="m_off" priority="1">
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
            <xsl:when test="matches($v_text, '^\d{4}(هـ)*\s*-\s*\d{4}(هـ)*')">
                <xsl:variable name="v_onset" select="replace($v_text, '^(\d{4})(هـ)*\s*-\s*(\d{4})(هـ)*.*', '$1')"/>
                <xsl:variable name="v_terminus" select="replace($v_text, '^(\d{4})(هـ)*\s*-\s*(\d{4})(هـ)*.*', '$3')"/>
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
            <xsl:when test="matches(., '^\d{4}-\d{2}-\d{2}$')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <!--<xsl:attribute name="type" select="'onset'"/>-->
                    <xsl:attribute name="when" select="."/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches(., '^\d{4}-')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:attribute name="when" select="replace($v_text, '^(\d{4})\s*-.*$', '$1')"/>
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
            <xsl:when test="matches(., '^\d{4}\s*(هـ)')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="datingMethod" select="'#cal_islamic'"/>
                    <xsl:attribute name="when-custom" select="replace($v_text, '^(\d{4}).+$', '$1')"/>
                    <xsl:apply-templates mode="m_post-process"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:bibl[ancestor::tei:note/@type = 'holdings']" mode="m_post-process" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:attribute name="corresp">
                <xsl:value-of select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'tei-ref', '', '', $p_local-authority)"/>
            </xsl:attribute>
            <xsl:apply-templates mode="m_post-process" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblScope" mode="m_post-process">
        <xsl:variable name="v_content" select="normalize-space(.)"/>
        <xsl:call-template name="t_test-for-dates">
            <xsl:with-param name="p_input" select="$v_content"/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="contains($v_content, '#')">
                <xsl:element name="biblScope">
                    <xsl:attribute name="unit" select="'issue'"/>
                    <xsl:value-of select="substring-after($v_content, '#')"/>
                </xsl:element>
            </xsl:when>
            <!--<xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>-->
        </xsl:choose>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
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
    <xsl:template match="tei:persName[contains(.,'،')]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_post-process"/>
            <xsl:element name="forename">
                <xsl:value-of select="normalize-space(substring-after(.,'،'))"/>
            </xsl:element>
            <xsl:text> </xsl:text>
            <xsl:element name="surname">
                <xsl:value-of select="normalize-space(substring-before(.,'،'))"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
     <xsl:template match="tei:placeName[not(contains(.,']'))][contains(.,'،')]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_post-process"/>
            <xsl:value-of select="normalize-space(substring-before(.,'،'))"/>
        </xsl:copy>
         <xsl:text> </xsl:text>
         <xsl:element name="country">
             <xsl:value-of select="normalize-space(substring-after(.,'،'))"/>
         </xsl:element>
    </xsl:template>
</xsl:stylesheet>
