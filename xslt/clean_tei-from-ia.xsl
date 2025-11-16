<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_group" select="false()"/>
    <xsl:param name="p_source" select="'oape:org:440'"/>
    <!-- remove nested bibls and dates -->
    <xsl:template match="tei:note/tei:bibl | tei:date/tei:date" mode="m_post-process" priority="100">
        <xsl:text> </xsl:text>
        <xsl:apply-templates mode="m_post-process"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template mode="m_post-process" match="tei:title[@ref = 'NA'][preceding-sibling::tei:note[@type = 'title']/tei:title]"/>
    <!-- group -->
    <xsl:template match="tei:standOff/tei:listBibl" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:choose>
                <xsl:when test="$p_group = false()">
                    <xsl:apply-templates mode="m_post-process" select="node()"/>
                </xsl:when>
                <xsl:when test="$p_group = true()">
                    <xsl:apply-templates mode="m_identity-transform" select="tei:head"/>
                    <!-- group biblStruct with IDs by IDs -->
                    <listBibl>
                        <head>
                            <xsl:value-of select="count(distinct-values(tei:biblStruct[@type = 'periodical']/descendant::tei:idno[@type = 'wiki']))"/>
                            <xsl:text> periocicals with IDs</xsl:text>
                        </head>
                        <xsl:for-each-group group-by="descendant::tei:idno[@type = 'wiki']" select="tei:biblStruct[@type = 'periodical'][descendant::tei:idno[@type = 'wiki']]">
                            <xsl:sort select="current-grouping-key()"/>
                            <xsl:variable name="v_listBibl">
                                <listBibl>
                                    <xsl:copy-of select="current-group()"/>
                                </listBibl>
                            </xsl:variable>
                            <xsl:call-template name="t_group-biblStruct">
                                <xsl:with-param name="p_input" select="$v_listBibl"/>
                            </xsl:call-template>
                        </xsl:for-each-group>
                    </listBibl>
                    <!-- group biblStruct with titles by titles -->
                    <listBibl>
                        <head>with titles but no resolved IDs</head>
                        <xsl:for-each-group group-by="tei:monogr/tei:title" select="tei:biblStruct[@type = 'periodical'][not(descendant::tei:idno[@type = 'wiki'])][tei:monogr/tei:title]">
                            <xsl:sort select="current-grouping-key()"/>
                            <xsl:variable name="v_listBibl">
                                <listBibl>
                                    <xsl:copy-of select="current-group()"/>
                                </listBibl>
                            </xsl:variable>
                            <xsl:call-template name="t_group-biblStruct">
                                <xsl:with-param name="p_input" select="$v_listBibl"/>
                            </xsl:call-template>
                        </xsl:for-each-group>
                    </listBibl>
                    <!-- group biblStruct without both titles and IDs-->
                    <listBibl>
                        <head>with out titles and resolvable IDs</head>
                        <xsl:for-each select="tei:biblStruct[not(descendant::tei:idno[@type = 'wiki'])][not(tei:monogr/tei:title)]">
                            <xsl:variable name="v_listBibl">
                                <listBibl>
                                    <xsl:copy-of select="."/>
                                </listBibl>
                            </xsl:variable>
                            <xsl:call-template name="t_group-biblStruct">
                                <xsl:with-param name="p_input" select="$v_listBibl"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </listBibl>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="t_group-biblStruct">
        <xsl:param name="p_input"/>
        <!-- reproduce the main bibliographic information -->
        <biblStruct>
            <xsl:apply-templates mode="m_identity-transform" select="$p_input/descendant::tei:biblStruct[1]/@*"/>
            <!-- add source information if there is only a single record at the Internet Archive -->
            <xsl:if test="count($p_input/descendant::tei:biblStruct) = 1">
                <xsl:attribute name="source" select="concat('oape:org:440', ' ', concat($p_url-resolve-ia, $p_input/descendant::tei:biblStruct/descendant::tei:idno[@type = 'classmark'][1]))"/>
            </xsl:if>
            <monogr>
                <xsl:apply-templates mode="m_identity-transform" select="$p_input/descendant::tei:biblStruct[1]/descendant::tei:title[1]"/>
                <xsl:for-each-group group-by="." select="$p_input/descendant::tei:idno[@type = ('jaraid', 'oape', 'OCLC', 'wiki')]">
                    <xsl:apply-templates mode="m_identity-transform" select="."/>
                </xsl:for-each-group>
                <xsl:for-each-group group-by="." select="$p_input/descendant::tei:textLang">
                    <xsl:apply-templates mode="m_identity-transform" select="."/>
                </xsl:for-each-group>
                <xsl:for-each-group group-by="." select="$p_input/descendant::tei:editor">
                    <xsl:apply-templates mode="m_identity-transform" select="."/>
                </xsl:for-each-group>
                <xsl:for-each-group group-by="." select="$p_input/descendant::tei:respStmt">
                    <xsl:apply-templates mode="m_identity-transform" select="."/>
                </xsl:for-each-group>
                <xsl:if test="$p_input/descendant::tei:imprint/tei:pubPlace">
                    <imprint>
                        <xsl:for-each-group group-by="." select="$p_input/descendant::tei:imprint/tei:pubPlace">
                            <xsl:apply-templates mode="m_identity-transform" select="."/>
                        </xsl:for-each-group>
                    </imprint>
                </xsl:if>
            </monogr>
            <!-- group existing notes by type -->
            <xsl:for-each-group group-by="@type" select="$p_input/descendant::tei:biblStruct/tei:note">
                <note source="oape:org:440">
                    <xsl:attribute name="type" select="current-grouping-key()"/>
                    <list>
                        <!-- notes by content to reduce redundancy, this reduces the tracability of the source for individual claims -->
                        <xsl:for-each-group select="current-group()" group-by=".">
                            <item>
                                <!-- add source information: there is no way to look behind the grouping function from which $p_input originated -->
                                <!--<xsl:attribute name="source" select="$p_input/descendant::tei:biblStruct[descendant::tei:idno[@type = 'ARK']][1]/descendant::tei:idno[@type = 'ARK']"/>-->
                                <!--<xsl:attribute name="source"
                                    select="concat($p_url-resolve-ia, current-group()/ancestor::tei:biblStruct[descendant::tei:idno[@type = 'classmark']][1]/tei:monogr/tei:idno[@type = 'classmark'])"/>-->
                                <!-- remove the surrounding note -->
                                <xsl:apply-templates mode="m_identity-transform" select="./@source | ./node()"/>
                            </item>
                        </xsl:for-each-group>
                    </list>
                </note>
            </xsl:for-each-group>
            <!-- note for holdings -->
            <note resp="#xslt" type="holdings">
                <list>
                    <item source="oape:org:440">
                        <label>
                            <orgName ref="oape:org:440">Internet Archive</orgName>
                        </label>
                        <listBibl>
                            <xsl:for-each select="$p_input/descendant::tei:biblStruct">
                                <xsl:sort select="tei:monogr/tei:imprint/tei:date[@when][1]/@when"/>
                                <xsl:sort select="tei:monogr/tei:biblScope[@unit = 'volume'][1]/@from"/>
                                <xsl:sort select="tei:monogr/tei:biblScope[@unit = 'issue'][1]/@from"/>
                                <bibl resp="#xslt" type="copy">
                                    <!-- select inclusions -->
                                    <xsl:apply-templates mode="m_identity-transform"
                                        select="descendant::tei:idno[@type = ('classmark', 'ARK')] | tei:monogr/tei:biblScope | tei:monogr/tei:imprint/tei:date"/>
                                </bibl>
                            </xsl:for-each>
                        </listBibl>
                    </item>
                </list>
            </note>
        </biblStruct>
    </xsl:template>
    <!-- titles ending in dates -->
    <xsl:template match="tei:note[@type = 'title'][not(child::element())][matches(., '^(.*?\D)((\d{4})\s*-\s*)?(\d{4})$')]" mode="m_post-process">
        <xsl:analyze-string regex="^(.*?\D)((\d{{4}})\s*-\s*)?(\d{{4}})$" select=".">
            <xsl:matching-substring>
                <xsl:variable name="v_content" select="regex-group(1)"/>
                <xsl:variable name="v_onset" select="regex-group(3)"/>
                <xsl:variable name="v_terminus" select="regex-group(4)"/>
                <!-- title -->
                <xsl:element name="note">
                    <xsl:attribute name="type" select="'title'"/>
                    <xsl:value-of select="normalize-space($v_content)"/>
                    <xsl:text> </xsl:text>
                    <!-- dates -->
                    <xsl:choose>
                        <xsl:when test="$v_onset != '' and $v_terminus != ''">
                            <xsl:element name="date">
                                <xsl:attribute name="type" select="'onset'"/>
                                <xsl:value-of select="$v_onset"/>
                            </xsl:element>
                            <xsl:element name="date">
                                <xsl:attribute name="type" select="'terminus'"/>
                                <xsl:value-of select="$v_terminus"/>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="$v_terminus != ''">
                            <xsl:element name="date">
                                <xsl:value-of select="$v_terminus"/>
                            </xsl:element>
                        </xsl:when>
                    </xsl:choose>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    <!-- initial steps -->
    <xsl:template match="tei:idno" mode="m_off">
        <xsl:copy>
            <!-- add attributes -->
            <xsl:choose>
                <xsl:when test="not(preceding-sibling::tei:idno)">
                    <xsl:attribute name="type" select="'classmark'"/>
                    <xsl:attribute name="source" select="$p_source"/>
                </xsl:when>
                <xsl:when test="matches(., '^ark:')">
                    <xsl:attribute name="type" select="'ARK'"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:dateAdded" mode="m_post-process">
        <xsl:element name="date">
            <xsl:attribute name="type" select="'acquisition'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
