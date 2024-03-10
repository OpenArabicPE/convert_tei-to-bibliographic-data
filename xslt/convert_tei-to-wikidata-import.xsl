<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.wikidata.org/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:import href="functions.xsl"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@*[not(name() = 'source')]"/>
            <xsl:apply-templates select="@source"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/">
        <items>
            <xsl:apply-templates select="descendant::tei:biblStruct"/>
        </items>
    </xsl:template>
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
        <xsl:for-each select="tokenize($v_source, '\s+')">
            <!-- reference URL: P854 -->
            <xsl:choose>
                <xsl:when test="starts-with(., 'http')">
                    <P854>
                        <xsl:value-of select="."/>
                    </P854>
                </xsl:when>
                <!-- local URLs need to be resolved or omitted -->
                <xsl:when test="starts-with(., '../')">
                    <P854>
                        <xsl:value-of select="."/>
                    </P854>
                </xsl:when>
                <!-- stated in: P248, requires a QItem -->
                <xsl:otherwise>
                    <P248>
                        <xsl:value-of select="."/>
                    </P248>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    <!-- nodes to be converted -->
    <xsl:template match="tei:biblStruct">
        <item>
            <xsl:if test="descendant::tei:idno[@type = 'wiki']">
                <xsl:attribute name="xml:id" select="descendant::tei:idno[@type = 'wiki'][1]"/>
            </xsl:if>
            <xsl:apply-templates select="@oape:frequency | @type | @subtype | node()"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:biblStruct/@subtype | tei:biblStruct/@type">
        <P31>
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
    <xsl:template match="tei:editor">
        <!-- converting to a reconciled Wikidata item! -->
        <xsl:choose>
            <xsl:when test="tei:persName[matches(@ref, 'wiki:Q\d+|viaf:\d+')]">
                <P98>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="tei:persName[matches(@ref, 'wiki:Q\d+|viaf:\d+')]"/>
                    </xsl:call-template>
                    <xsl:choose>
                        <!-- linked to Wikidata -->
                        <xsl:when test="tei:persName[matches(@ref, 'wiki:Q\d+')]">
                            <xsl:call-template name="t_QItem">
                                <xsl:with-param name="p_input" select="replace(tei:persName[matches(@ref, 'wiki:Q\d+')][1]/@ref, '^.*wiki:(Q\d+).*$', '$1')"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- linked to Geonames -->
                        <xsl:when test="tei:persName[matches(@ref, 'viaf:\d+')]">
                            <xsl:call-template name="t_string-value">
                                <xsl:with-param name="p_input" select="tei:persName[matches(@ref, 'viaf:\d+')][1]"/>
                            </xsl:call-template>
                            <P214>
                                <xsl:value-of select="replace(tei:persName[matches(@ref, 'viaf:\d+')][1]/@ref, '^.*viaf:(\d+).*$', '$1')"/>
                            </P214>
                        </xsl:when>
                    </xsl:choose>
                </P98>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_name-string" select="tei:persName"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:editor/tei:persName" mode="m_name-string">
        <P2093>
            <xsl:apply-templates mode="m_string" select="."/>
        </P2093>
    </xsl:template>
    <xsl:template match="tei:idno">
        <xsl:choose>
            <xsl:when test="@type = 'ht_bib_key'">
                <P1844>
                    <xsl:apply-templates mode="m_string" select="."/>
                </P1844>
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
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:imprint">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:monogr">
        <xsl:apply-templates select="@oape:frequency | node()"/>
    </xsl:template>
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
                    <xsl:text>Unidentified publisher: </xsl:text>
                    <xsl:value-of select="tei:orgName[1]"/>
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
            <string>
                <xsl:value-of select="."/>
            </string>
        </P2896>
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
