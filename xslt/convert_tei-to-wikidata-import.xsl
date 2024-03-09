<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@*[not(name() = 'source')]"/>
            <xsl:apply-templates select="@source"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!--  remove attributes  -->
    <xsl:template match="@xml:id | tei:monogr/@xml:lang | tei:title/@level | tei:title/@ref"/>
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
            <xsl:apply-templates select="@type | @subtype | node()"/>
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
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:if test="@when">
                <string>
                    <xsl:value-of select="@when"/>
                </string>
            </xsl:if>
            <!-- notBefore -->
            <!-- notAfter -->
        </P571>
    </xsl:template>
    <xsl:template match="tei:editor">
        <!-- converting to a reconciled Wikidata item! -->
        <xsl:choose>
            <xsl:when test="tei:persName[matches(@ref, 'wiki:Q\d+')]">
                <P98>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="tei:persName[matches(@ref, 'wiki:Q\d+')]"/>
                    </xsl:call-template>
                    <xsl:call-template name="t_QItem">
                        <xsl:with-param name="p_input" select="replace(tei:persName[matches(@ref, 'wiki:Q\d+')][1]/@ref, '^.*wiki:(Q\d+).*$', '$1')"/>
                    </xsl:call-template>
                </P98>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_name-string" select="tei:persName"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:editor/tei:persName" mode="m_name-string">
        <P2093>
            <!--            <xsl:apply-templates select="@*"/>-->
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="parent::element()"/>
            </xsl:call-template>
            <xsl:call-template name="t_string-value">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
        </P2093>
    </xsl:template>
    <xsl:template match="tei:idno">
        <xsl:choose>
            <xsl:when test="@type = 'ht_bib_key'">
                <P1844>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                    <xsl:call-template name="t_string-value">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                </P1844>
            </xsl:when>
            <xsl:when test="@type = 'OCLC'">
                <P243>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                    <xsl:call-template name="t_string-value">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                </P243>
            </xsl:when>
            <xsl:when test="@type = 'VIAF'">
                <P214>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                    <xsl:call-template name="t_string-value">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                </P214>
            </xsl:when>
            <xsl:when test="@type = 'wiki'">
                <xsl:call-template name="t_QItem">
                    <xsl:with-param name="p_input" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="@type = 'zdb'">
                <P1042>
                    <xsl:call-template name="t_source">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                    <xsl:call-template name="t_string-value">
                        <xsl:with-param name="p_input" select="."/>
                    </xsl:call-template>
                </P1042>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:imprint">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:monogr">
        <xsl:apply-templates/>
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
            <xsl:call-template name="t_reconcile-lang">
                <xsl:with-param name="p_lang" select="@mainLang"/>
            </xsl:call-template>
        </P407>
    </xsl:template>
    <!-- this template is currently unused and not necessary -->
    <xsl:template name="t_reconcile-lang">
        <xsl:param name="p_lang"/>
        <xsl:choose>
            <xsl:when test="$p_lang = ''">
                <xsl:call-template name="t_QItem">
                    <xsl:with-param name="p_input" select=""/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <string>
                    <xsl:value-of select="$p_lang"/>
                </string>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:title">
        <P1476>
            <!--            <xsl:apply-templates select="@*[not(name() = 'source')]"/>-->
            <xsl:call-template name="t_source">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:call-template name="t_string-value">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
        </P1476>
    </xsl:template>
</xsl:stylesheet>
