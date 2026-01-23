<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.wikidata.org/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:import href="convert_tei-to-wikidata-import_functions.xsl"/>
    <xsl:param name="p_output-mode" select="'holdings'"/>
    <xsl:variable name="v_output-directory" select="'Wikidata/'"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'holdings'">
                <xsl:result-document href="{$v_base-directory}{$v_output-directory}OpenRefine/{$v_file-name_input}_holdings.Wikidata.xml" method="xml">
                    <collection>
                        <!-- bibliographic entries -->
                        <items>
                            <head>Holdings</head>
                            <xsl:apply-templates mode="m_tei2wikidata_holdings"
                                select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical' or tei:monogr/tei:title[@level = 'j']][tei:note[@type = 'holdings']][descendant::tei:idno/@type = $p_acronym-wikidata]"
                            />
                        </items>
                    </collection>
                </xsl:result-document>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'qs'">
                <xsl:result-document href="{$v_base-directory}{$v_output-directory}QuickStatements/{$v_file-name_input}.qs" method="text">
                    <!-- periodicals with QID-->
                    <xsl:message>
                        <xsl:text>Converting bibls with QID to QuickStatements</xsl:text>
                    </xsl:message>
                    <xsl:apply-templates mode="m_tei2qs"
                        select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical' or tei:monogr/tei:title[@level = 'j']][descendant::tei:idno/@type = $p_acronym-wikidata or descendant::tei:title[matches(@ref, concat($p_acronym-wikidata, ':Q\d+'))]]"/>
                    <!-- new items: without an idno pointing to Wikidata and confirmed to be missing from Wikidata by a human -->
                    <xsl:message>
                        <xsl:text>Converting bibls without QID to QuickStatements</xsl:text>
                    </xsl:message>
                    <xsl:apply-templates mode="m_tei2qs"
                        select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical ' or tei:monogr/tei:title[@level = 'j']][not(descendant::tei:idno/@type = $p_acronym-wikidata or descendant::tei:title[matches(@ref, concat($p_acronym-wikidata, ':Q\d+'))])]"
                    /> <!-- why was "[tei:monogr/tei:title[@ref = 'NA'][not(@resp = '#xslt')]]" added to the XPath? -->
                </xsl:result-document>
            </xsl:when>
            <xsl:when test="$p_output-mode = ('qs-holdings', 'holdings-qs')">
                <xsl:result-document href="{$v_base-directory}{$v_output-directory}QuickStatements/{$v_file-name_input}_holdings.qs" method="text">
                    <xsl:apply-templates mode="m_tei2qs_holdings"
                        select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical' or tei:monogr/tei:title[@level = 'j']][descendant::tei:idno/@type = $p_acronym-wikidata or descendant::tei:title[matches(@ref, concat($p_acronym-wikidata, ':Q\d+'))]]"
                    />
                </xsl:result-document>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'qs-ids'">
                <xsl:result-document href="{$v_base-directory}{$v_output-directory}QuickStatements/{$v_file-name_input}_ids.qs" method="text">
                    <xsl:apply-templates mode="m_tei2qs_ids"
                        select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical' or tei:monogr/tei:title[@level = 'j']][descendant::tei:idno/@type = $p_acronym-wikidata or descendant::tei:title[matches(@ref, concat($p_acronym-wikidata, ':Q\d+'))]]"
                    />
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="{$v_base-directory}{$v_output-directory}OpenRefine/{$v_file-name_input}.Wikidata.xml" method="xml">
                    <collection>
                        <xsl:if test="descendant::tei:standOff/descendant::tei:biblStruct">
                            <!-- periodicals -->
                            <items>
                                <head>already in Wikidata</head>
                                <xsl:apply-templates mode="m_tei2wikidata"
                                    select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical'][descendant::tei:idno/@type = $p_acronym-wikidata or descendant::tei:title[matches(@ref, concat($p_acronym-wikidata, ':Q\d+'))]]"
                                />
                            </items>
                            <!-- periodicals without QID -->
                            <items>
                                <head>not in Wikidata</head>
                                <xsl:apply-templates mode="m_tei2wikidata"
                                    select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical'][not(descendant::tei:idno/@type = $p_acronym-wikidata)]"/>
                                <xsl:apply-templates mode="m_tei2wikidata" select="descendant::tei:standOff/descendant::tei:biblStruct[not(@type = 'periodical')][tei:monogr/tei:title[@level = 'j']]"/>
                            </items>
                            <!-- bibliographic info but no periodicals -->
                            <items>
                                <head>no periodicals</head>
                                <xsl:apply-templates mode="m_tei2wikidata"
                                    select="descendant::tei:standOff/descendant::tei:biblStruct[not(@type = 'periodical')][not(tei:monogr/tei:title[@level = 'j'])]"/>
                            </items>
                        </xsl:if>
                        <!-- people from the personography  -->
                        <xsl:if test="descendant::tei:standOff/descendant::tei:person">
                            <items>
                                <head>already in Wikidata</head>
                                <xsl:apply-templates mode="m_tei2wikidata" select="descendant::tei:standOff/descendant::tei:person[tei:occupation][descendant::tei:idno/@type = $p_acronym-wikidata]"/>
                            </items>
                            <items>
                                <head>not in Wikidata</head>
                                <xsl:apply-templates mode="m_tei2wikidata"
                                    select="descendant::tei:standOff/descendant::tei:person[tei:occupation][not(descendant::tei:idno/@type = $p_acronym-wikidata)]"/>
                            </items>
                        </xsl:if>
                        <xsl:if test="descendant::tei:standOff/descendant::tei:org">
                            <!-- orgs from the organizationography  -->
                            <items>
                                <head>already in Wikidata</head>
                                <xsl:apply-templates mode="m_tei2wikidata"
                                    select="descendant::tei:standOff/tei:listOrg[@type = 'holdings']/descendant::tei:org[descendant::tei:idno/@type = $p_acronym-wikidata]"/>
                            </items>
                            <items>
                                <head>not in Wikidata</head>
                                <xsl:apply-templates mode="m_tei2wikidata"
                                    select="descendant::tei:standOff/tei:listOrg[@type = 'holdings']/descendant::tei:org[not(descendant::tei:idno/@type = $p_acronym-wikidata)]"/>
                            </items>
                        </xsl:if>
                    </collection>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
