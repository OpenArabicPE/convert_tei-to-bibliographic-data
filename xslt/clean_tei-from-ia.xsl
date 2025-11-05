<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <!-- remove nested bibls -->
    <xsl:template match="tei:note/tei:bibl" mode="m_post-process" priority="100">
        <xsl:text> </xsl:text>
        <xsl:apply-templates mode="m_post-process"/>
    </xsl:template>
    <!-- group -->
    <xsl:template match="tei:standOff/tei:listBibl" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:apply-templates mode="m_identity-transform" select="tei:head"/>
            <!-- group biblStruct with IDs by IDs -->
            <listBibl>
                <head>with IDs</head>
                <xsl:for-each-group group-by="descendant::tei:idno[@type = 'wiki']" select="tei:biblStruct[descendant::tei:idno[@type = 'wiki']]">
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
                <xsl:for-each-group group-by="tei:monogr/tei:title" select="tei:biblStruct[not(descendant::tei:idno[@type = 'wiki'])][tei:monogr/tei:title]">
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
            <!-- group existing notes -->
            <xsl:for-each-group group-by="@type" select="$p_input/descendant::tei:biblStruct/tei:note">
                <note source="oape:org:440">
                    <xsl:attribute name="type" select="current-grouping-key()"/>
                    <list>
                        <!-- notes by content to reduce redundancy, this reduces the tracability of the source for individual claims -->
                        <xsl:for-each select="current-group()">
                            <item>
                                <!-- add source information -->
                                <!--<xsl:attribute name="source" select="$p_input/descendant::tei:biblStruct[descendant::tei:idno[@type = 'ARK']][1]/descendant::tei:idno[@type = 'ARK']"/>-->
                                <xsl:attribute name="source"
                                    select="concat($p_url-resolve-ia, $p_input/descendant::tei:biblStruct[descendant::tei:idno[@type = 'classmark']][1]/descendant::tei:idno[@type = 'classmark'])"/>
                                <!-- remove the surrounding note -->
                                <xsl:apply-templates mode="m_identity-transform" select="./node()"/>
                            </item>
                        </xsl:for-each>
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
</xsl:stylesheet>
