<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <!-- remove all orgs which are already part of the organizationography -->
    <xsl:template match="tei:org[parent::tei:listOrg][tei:orgName[@ref]]" mode="m_off"/>
    <!-- dates-->
    <!-- remove redundant IDs -->
    <xsl:template match="tei:idno[@type = 'zdb'][starts-with(., 'ZDB')]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="substring-after(., 'ZDB')"/>
        </xsl:copy>
    </xsl:template>
    <!-- biblScope:
        - separate along ";"
        - separate along "-"
        - parse volume, issue, date
    -->
    <xsl:template match="tei:biblScope[ancestor::tei:note[@type = 'holdings']]" mode="m_post-process" priority="200">
        <xsl:choose>
            <!-- split sequences -->
            <xsl:when test="matches(., '.;.')">
                <!-- 1. bit -->
                <xsl:copy>
                    <!--                <xsl:element name="bibl">-->
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:value-of select="replace(., '^(.*?);.+$', '$1')"/>
                    <!--</xsl:element>-->
                </xsl:copy>
                <!-- 2. bit -->
                <xsl:copy>
                    <!--                <xsl:element name="bibl">-->
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:value-of select="replace(., '^(.*?);\s*(.+)$', '$2')"/>
                    <!--</xsl:element>-->
                </xsl:copy>
            </xsl:when>
            <!-- split ranges -->
            <xsl:when test="matches(., '.\s-\s.')">
                <!-- 1. bit -->
                <xsl:copy>
                    <!--                <xsl:element name="bibl">-->
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:value-of select="replace(., '^(.*?)\s-\s.+$', '$1')"/>
                    <!--</xsl:element>-->
                </xsl:copy>
                <!-- 2. bit -->
                <xsl:copy>
                    <!--                <xsl:element name="bibl">-->
                    <xsl:attribute name="type" select="'terminus'"/>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:value-of select="replace(., '^(.*?)\s-\s(.+)$', '$2')"/>
                    <!--</xsl:element>-->
                </xsl:copy>
            </xsl:when>
            <!-- parse content
                - this should not parse every four-digit string as a year
            -->
            <!-- starting with dates -->
            <xsl:when test="matches(., '^\d{4},\s*\d{1,2}\.\s*\w{3}\.')">
                <xsl:variable name="v_string-date" select="replace(., '^(\d{4},\s*\d{1,2}\.\s*\w{3}\.).*$', '$1')"/>
                <xsl:variable name="v_string-remain" select="replace(., '^(\d{4},\s*\d{1,2}\.\s*\w{3}\.)(.*)$', '$2')"/>
                <xsl:variable name="v_type" select="@type"/>
                <xsl:element name="bibl">
<!--                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>-->
                    <xsl:element name="date">
                        <xsl:analyze-string regex="^(\d{{4}}),\s*(\d{{1,2}})\.\s*(\w{{3}})\." select="$v_string-date">
                            <xsl:matching-substring>
                                <xsl:variable name="v_year" select="regex-group(1)"/>
                                <xsl:variable name="v_month" select="oape:date-convert-months( regex-group(3), 'number', 'de', '#cal_gregorian')"/>
                                <xsl:variable name="v_month-number">
                                    <xsl:choose>
                                        <xsl:when test="$v_month = ''">
                                            <xsl:value-of select="'xx'"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="format-number(number($v_month), '00')"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:variable name="v_day" select="format-number(number(regex-group(2)), '00')"/>
                                <xsl:if test="$v_type != ''">
                                    <xsl:attribute name="type" select="$v_type"/>
                                </xsl:if>
                                <xsl:attribute name="when">
                                    <xsl:value-of select="concat($v_year, '-', $v_month-number, '-', $v_day)"/>
                                </xsl:attribute>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                        <xsl:value-of select="$v_string-date"/>
                    </xsl:element>
                    <xsl:value-of select="$v_string-remain"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="matches(., '((\d+)\.)*(1\d{3}(=\d{4})*)(,(\d+))*')">
                <xsl:variable name="v_type" select="@type"/>
                <xsl:analyze-string regex="((\d+)\.)*(1\d{{3}}(=\d{{4}})*)(,(\d+))*(.*)$" select=".">
                    <xsl:matching-substring>
                        <xsl:element name="bibl">
                            <xsl:if test="regex-group(2)">
                                <xsl:element name="biblScope">
                                    <xsl:attribute name="unit" select="'volume'"/>
                                    <xsl:choose>
                                        <xsl:when test="$v_type = 'onset'">
                                            <xsl:attribute name="from" select="regex-group(2)"/>
                                        </xsl:when>
                                        <xsl:when test="$v_type = 'terminus'">
                                            <xsl:attribute name="to" select="regex-group(2)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:attribute name="from" select="regex-group(2)"/>
                                            <xsl:attribute name="to" select="regex-group(2)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="regex-group(2)"/>
                                </xsl:element>
                            </xsl:if>
                            <xsl:element name="date">
                                <xsl:if test="$v_type != ''">
                                    <xsl:attribute name="type" select="$v_type"/>
                                </xsl:if>
                                <xsl:value-of select="regex-group(3)"/>
                            </xsl:element>
                            <!-- also test if the assumed issue number isn't directly followed by a "." -->
                            <xsl:if test="regex-group(5) and not(matches(regex-group(7), '^\.'))">
                                <xsl:element name="biblScope">
                                    <xsl:attribute name="unit" select="'issue'"/>
                                    <xsl:choose>
                                        <xsl:when test="$v_type = 'onset'">
                                            <xsl:attribute name="from" select="regex-group(6)"/>
                                        </xsl:when>
                                        <xsl:when test="$v_type = 'terminus'">
                                            <xsl:attribute name="to" select="regex-group(6)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:attribute name="from" select="regex-group(6)"/>
                                            <xsl:attribute name="to" select="regex-group(6)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="regex-group(6)"/>
                                </xsl:element>
                            </xsl:if>
                            <!-- trailing content ... -->
                            <xsl:if test="matches(regex-group(7), '^\.')">
                                <xsl:value-of select="regex-group(5)"/>
                            </xsl:if>
                            <xsl:value-of select="regex-group(7)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--  ONLY DO THIS AT THE END OF A TRANSFORMATION  -->
    <!-- unnest bibls -->
    <xsl:template match="tei:bibl[ancestor::tei:note[@type = 'holdings']][tei:bibl]" mode="m_off" priority="20">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | node()[not(local-name() = 'bibl')]"/>
        </xsl:copy>
        <xsl:apply-templates mode="m_post-process" select="tei:bibl"/>
    </xsl:template>
    <!-- merge ranges of bibl -->
    <xsl:template match="tei:bibl[ancestor::tei:note[@type = 'holdings']][tei:date[@type = 'onset']][tei:biblScope[@from][not(@to)]]" mode="m_off" priority="20">
        <xsl:copy>
            <!-- IDs from potential parent -->
            <xsl:if test="parent::tei:bibl">
                <xsl:apply-templates mode="m_identity-transform" select="parent::tei:bibl/tei:idno"/>
            </xsl:if>
            <!-- dates -->
            <xsl:apply-templates mode="m_post-process" select="tei:date | following-sibling::tei:bibl[tei:date[@type = 'terminus']][tei:biblScope[@to][not(@from)]][1]/tei:date"/>
            <!-- biblScope -->
            <xsl:for-each select="tei:biblScope">
                <xsl:copy select=".">
                    <!-- unit, from -->
                    <xsl:apply-templates mode="m_identity-transform" select="./@*"/>
                    <!-- to -->
                    <xsl:apply-templates mode="m_identity-transform"
                        select="parent::tei:bibl/following-sibling::tei:bibl[tei:date[@type = 'terminus']][tei:biblScope[@unit = current()/@unit][@to][not(@from)]][1]/tei:biblScope[@unit = current()/@unit]/@to"/>
                    <!-- content -->
                    <!--<xsl:value-of select="."/>
                    <xsl:value-of select="'-'"/>
                    <xsl:value-of select="parent::tei:bibl/following-sibling::tei:bibl[tei:date[@type = 'terminus']][tei:biblScope[@unit = current()/@unit][@to][not(@from)]][1]/tei:biblScope[@unit = current()/@unit]"/>-->
                </xsl:copy>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:bibl[ancestor::tei:note[@type = 'holdings']][tei:date[@type = 'terminus']][tei:biblScope[@to][not(@from)]]" mode="m_off" priority="20"/>
</xsl:stylesheet>
