<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.wikidata.org/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:import href="convert_tei-to-wikidata-import_functions.xsl"/>
    <xsl:param name="p_output-mode" select="'holdings'"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'holdings'">
                <xsl:result-document href="{$v_base-directory}refine/{$v_file-name_input}_holdings.Wikidata.xml">
                    <collection>
                        <!-- bibliographic entries -->
                        <items>
                            <head>Holdings</head>
                            <xsl:apply-templates mode="m_tei2wikidata_holdings"
                                select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical'][tei:note[@type = 'holdings']][descendant::tei:idno/@type = $p_acronym-wikidata]"/>
                        </items>
                    </collection>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="{$v_base-directory}refine/{$v_file-name_input}.Wikidata.xml">
                    <collection>
                        <items>
                            <xsl:apply-templates mode="m_tei2wikidata"
                                select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical'][descendant::tei:idno/@type = $p_acronym-wikidata]"/>
                        </items>
                        <!-- periodicals without QID -->
                        <items>
                            <xsl:apply-templates mode="m_tei2wikidata"
                                select="descendant::tei:standOff/descendant::tei:biblStruct[@type = 'periodical'][not(descendant::tei:idno/@type = $p_acronym-wikidata)]"/>
                        </items>
                        <!-- no periodicals -->
                        <items>
                            <xsl:apply-templates mode="m_tei2wikidata" select="descendant::tei:standOff/descendant::tei:biblStruct[not(@type = 'periodical')]"/>
                        </items>
                        <!--  -->
                        <items>
                            <xsl:apply-templates select="descendant::tei:standOff/descendant::tei:person[tei:occupation]"/>
                        </items>
                    </collection>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
