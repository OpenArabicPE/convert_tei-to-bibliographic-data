<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:import href="../../authority-files/xslt/functions.xsl"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- first step: correct existing reference strings -->
    <xsl:template match="tei:rs[not(@ref)]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="matches(., 'Ṭ', 'i')">
                    <xsl:attribute name="ref" select="'#agt'"/>
                </xsl:when>
                <xsl:when test="matches(., '\+!', 'i')">
                    <xsl:attribute name="ref" select="'#aghart2'"/>
                </xsl:when>
                <xsl:when test="matches(., '\+', 'i')">
                    <xsl:attribute name="ref" select="'#aghart1'"/>
                </xsl:when>
                <xsl:when test="matches(., 'ʿAbd', 'i')">
                    <xsl:attribute name="ref" select="'#abd2'"/>
                </xsl:when>
                <!-- Philip Sadgrove -->
                <xsl:when test="matches(., 'S', 'i')">
                    <xsl:attribute name="ref" select="'#ags'"/>
                </xsl:when>
                <!-- Stacy Fahrenholdt -->
                <xsl:when test="matches(., 'SF', 'i')">
                    <xsl:attribute name="ref" select="'#aSF'"/>
                </xsl:when>
                <xsl:when test="matches(., 'M-K', 'i')">
                    <xsl:attribute name="ref" select="'#aMK'"/>
                </xsl:when>
                <xsl:when test="matches(., 'RC', 'i')">
                    <xsl:attribute name="ref" select="'#aRC'"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <!-- second step include information from <note type='sources'> into biblStruct/@source -->
    <xsl:template match="tei:biblStruct[tei:note[@type = 'sources']//tei:rs[@ref]]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- ammend @source
                1. look up sources
            
            -->
            <xsl:variable name="v_sources">
                <xsl:for-each-group select="tei:note[@type = 'sources']//tei:rs[@ref]" group-by="@ref">
                    <xsl:apply-templates select="." mode="m_ids"/>
                    <xsl:if test="position() != last()">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:variable>
            <xsl:attribute name="source" select="normalize-space(concat(@source, ' ', $v_sources))"/>
            <!-- replicate content -->
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:rs[@ref]" mode="m_ids">
        <xsl:variable name="v_target-id" select="substring-after(@ref, '#')"/>
        <xsl:choose>
            <xsl:when test="$v_target-id = ancestor::tei:TEI/descendant::tei:biblStruct/@xml:id">
                <xsl:value-of select="oape:query-biblstruct(ancestor::tei:TEI/descendant::tei:biblStruct[@xml:id = $v_target-id], 'id', '', $v_gazetteer, $p_local-authority)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>WARNING: couldn't find a biblStruct for "</xsl:text>
                    <xsl:value-of select="$v_target-id"/>
                    <xsl:text>"</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:rs[@ref]" mode="m_off">
        <xsl:variable name="v_target-id" select="substring-after(@ref, '#')"/>
        <xsl:choose>
            <xsl:when test="$v_target-id = ancestor::tei:TEI/descendant::element()/@xml:id">
                <xsl:variable name="v_target" select="ancestor::tei:TEI/descendant::element()[@xml:id = $v_target-id]"/>
                <xsl:choose>
                    <xsl:when test="$v_target/local-name() = ('bibl', 'biblStruct')">
                        <bibl>
                            <xsl:apply-templates select="@ref"/>
                            <xsl:apply-templates mode="m_citation" select="$v_target//tei:author[1]"/>
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates mode="m_citation" select="$v_target//tei:date[1]"/>
                        </bibl>
                    </xsl:when>
                    <xsl:when test="$v_target/tei:biblStruct">
                        <bibl>
                            <xsl:apply-templates select="@ref"/>
                            <xsl:for-each select="$v_target/tei:biblStruct">
                                <bibl>
                                    <xsl:apply-templates mode="m_citation" select="descendant::tei:author[1]"/>
                                    <xsl:text> </xsl:text>
                                    <xsl:apply-templates mode="m_citation" select="descendant::tei:date[1]"/>
                                </bibl>
                            </xsl:for-each>
                        </bibl>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy>
                            <xsl:apply-templates select="@* | node()"/>
                        </xsl:copy>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:author | tei:editor" mode="m_citation">
        <xsl:copy>
            <xsl:value-of select="descendant::tei:surname"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date" mode="m_citation">
        <xsl:copy>
            <xsl:value-of select="."/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
