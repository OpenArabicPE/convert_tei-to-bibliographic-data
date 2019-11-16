<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheets takes a <tei:div> as input and generates a <biblStruct> -->
    <xsl:function name="oape:bibliography-tei-div-to-biblstruct">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_source-monogr" select="$p_input/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr"/>
        <xsl:element name="biblStruct">
            <xsl:element name="analytic">
                <!-- article title -->
                <xsl:element name="title">
                    <xsl:attribute name="level" select="'a'"/>
                    <xsl:value-of select="oape:get-title-from-div($p_input)"/>
                </xsl:element>
                <!-- authorship  information -->
                <xsl:element name="author">
                    <xsl:copy-of select="oape:get-author-from-div($p_input)"/>
                </xsl:element>
                <!-- IDs: URL -->
                <xsl:for-each select="$p_input/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='url']">
                    <xsl:element name="idno">
                    <xsl:attribute name="type" select="'url'"/>
                    <xsl:value-of select="concat(.,'#',$p_input/@xml:id)"/>
                </xsl:element>
                </xsl:for-each>
            </xsl:element>
            <!-- copy information from the file's sourceDesc -->
            <xsl:element name="monogr">
                <!-- title -->
                <xsl:apply-templates select="$v_source-monogr/tei:title" mode="m_replicate"/>
                <!-- IDs -->
                <xsl:apply-templates select="$v_source-monogr/tei:idno" mode="m_replicate"/>
                <!-- text languages -->
                <xsl:apply-templates select="$v_source-monogr/tei:textLang" mode="m_replicate"/>
                <!-- editor -->
                <xsl:apply-templates select="$v_source-monogr/tei:editor" mode="m_replicate"/>
                <!-- imprint -->
                <xsl:apply-templates select="$v_source-monogr/tei:imprint" mode="m_replicate"/>
                <!-- volume and issue -->
                <xsl:apply-templates select="$v_source-monogr/tei:biblScope[not(@unit='page')]" mode="m_replicate"/>
                <!-- page numbers -->
                <xsl:element name="biblScope">
                    <xsl:attribute name="unit" select="'page'"/>
                    <xsl:variable name="v_page-onset" select="$p_input/preceding::tei:pb[@ed = 'print'][1]/@n"/>
                    <xsl:variable name="v_page_terminus">
                        <xsl:choose>
                            <xsl:when test="$p_input/descendant::tei:pb[@ed = 'print']">
                                <xsl:value-of select="$p_input/descendant::tei:pb[@ed = 'print'][last()]/@n"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$v_page-onset"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:attribute name="from" select="$v_page-onset"/>
                    <xsl:attribute name="to" select="$v_page_terminus"/>
                    <xsl:value-of select="concat($v_page-onset,'-',$v_page_terminus)"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:function>
    
    <!-- function to get the author(s) of a div -->
    <xsl:function name="oape:get-author-from-div">
        <xsl:param name="p_input"/>
        <xsl:choose>
            <xsl:when
                test="$p_input/child::tei:byline/descendant::tei:persName[not(ancestor::tei:note)]">
                <xsl:copy-of
                    select="$p_input/child::tei:byline/descendant::tei:persName[not(ancestor::tei:note)]"
                />
            </xsl:when>
            <xsl:when
                test="$p_input/child::tei:byline/descendant::tei:orgName[not(ancestor::tei:note)]">
                <xsl:copy-of
                    select="$p_input/child::tei:byline/descendant::tei:orgName[not(ancestor::tei:note)]"
                />
            </xsl:when>
            <xsl:when
                test="$p_input/descendant::tei:note[@type = 'bibliographic']/tei:bibl/tei:author">
                <xsl:copy-of
                    select="$p_input/descendant::tei:note[@type = 'bibliographic']/tei:bibl/tei:author/descendant::tei:persName"
                />
            </xsl:when>
            <xsl:when
                test="$p_input/descendant::tei:note[@type = 'bibliographic']/tei:bibl/tei:title[@level = 'j']">
                <xsl:copy-of
                    select="$p_input/descendant::tei:note[@type = 'bibliographic']/tei:bibl/tei:title[@level = 'j']"
                />
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <!-- function to get a title of a div -->
    <xsl:function name="oape:get-title-from-div">
        <xsl:param name="p_input"/>
            <xsl:if test="$p_input/@type = 'item' and $p_input/ancestor::tei:div[@type = 'section']">
                <xsl:apply-templates select="$p_input/ancestor::tei:div[@type = 'section']/tei:head"
                    mode="m_plain-text"/>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="$p_input/tei:head" mode="m_plain-text"/>
    </xsl:function>
    
    <xsl:template match="node()" mode="m_plain-text">
        <xsl:value-of select="normalize-space()"/>
    </xsl:template>
    <xsl:template match="tei:head/tei:note" mode="m_plain-text"/>
    
    <xsl:template match="node() | @*" mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_replicate"/>
</xsl:stylesheet>
