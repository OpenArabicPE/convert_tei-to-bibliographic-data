<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <xsl:output method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="true"/>
    <xsl:strip-space elements="*"/>
    
    <!-- this stylesheet translates <tei:biblStruct>s to  YAML for use in a wax site -->
    <xsl:import href="../../authority-files/xslt/functions.xsl"/>
    <xsl:param name="p_local-authority" select="'oape'"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_quot" select="'&quot;'"/>
    <xsl:variable name="v_key-value-sep" select="': '"/>
    <xsl:variable name="v_comma" select="','"/>
    <xsl:variable name="v_tab" select="'  '"/>
    
    <!-- testing -->
    <xsl:template match="/">
<!--        <xsl:result-document href="{concat($v_url-base, '/', $v_name-file, '.yml')}">-->
        <xsl:apply-templates select="descendant::tei:biblStruct" mode="m_tei-to-yaml"/>
        <!--</xsl:result-document>-->
    </xsl:template>  
    <xsl:template match="tei:biblStruct" mode="m_tei-to-yaml">
        <xsl:copy-of select="oape:bibliography-tei-to-wax(., 'ar')"/>
    </xsl:template>
    
    <xsl:function name="oape:bibliography-tei-to-wax">
        <xsl:param name="p_biblstruct"/>
        <xsl:param name="p_lang"/>
        <!-- output -->
        <xsl:value-of select="$v_new-line"/>
        <xsl:variable name="v_new-line" select="concat($v_new-line, $v_tab)"/>
        <!-- specific to wax -->
        <xsl:text>- </xsl:text>
        <xsl:text>pid</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:value-of select="$p_biblstruct/descendant::tei:idno[@type = $p_local-authority][1]"/>
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>label</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:apply-templates select="$p_biblstruct/descendant::tei:title[parent::tei:monogr][not(@type)][@xml:lang = $p_biblstruct/descendant::tei:textLang[1]/@mainLang][1]/text()" mode="m_tei-to-yaml"/>
        <!-- titles -->
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>titles</xsl:text><xsl:value-of select="$v_key-value-sep"/>
        <xsl:for-each select="$p_biblstruct/tei:monogr/tei:title[not(@type)]">
            <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/>
            <xsl:apply-templates select="." mode="m_tei-to-yaml"/>
        </xsl:for-each>
        <!--<xsl:for-each-group select="$p_biblstruct/tei:monogr/tei:title[not(@type = 'sub')]" group-by=".">
            <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/>
            <xsl:text>- </xsl:text><xsl:apply-templates select="text()" mode="m_tei-to-yaml"/><xsl:value-of select="$v_key-value-sep"/>
            <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/>
            <xsl:value-of select="$v_tab"/><xsl:text>lang</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:apply-templates select="@xml:lang" mode="m_tei-to-yaml"/>
        </xsl:for-each-group>-->
        <!-- volume, issue, pages -->
        <!-- language -->
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>lang</xsl:text><xsl:value-of select="$v_key-value-sep"/>
        <xsl:value-of select="$v_new-line"/>
        <xsl:value-of select="$v_tab"/> <xsl:text>- mainLang</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:apply-templates select="$p_biblstruct/descendant::tei:textLang[1]/@mainLang" mode="m_tei-to-yaml"/>
        <xsl:for-each select="$p_biblstruct/tei:monogr/tei:textLang/@otherLangs">
            <xsl:value-of select="$v_new-line"/>
            <xsl:value-of select="$v_tab"/> <xsl:text>- otherLangs</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:apply-templates select="." mode="m_tei-to-yaml"/>
        </xsl:for-each>
        <!--  editors  -->
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>editor</xsl:text><xsl:value-of select="$v_key-value-sep"/>
        <xsl:for-each select="$p_biblstruct/tei:monogr/tei:editor">
            <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/>
            <xsl:choose>
            <xsl:when test="tei:persName[@ref != 'NA']">
                <xsl:apply-templates select="tei:persName[@ref != 'NA'][1]" mode="m_tei-to-yaml"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="tei:persName[1]" mode="m_tei-to-yaml"/>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:for-each>
        <!-- imprint -->
  <!-- dates: potentially multiple -->
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>issued: </xsl:text><xsl:apply-templates select="$p_biblstruct/descendant::tei:date[parent::tei:imprint][@type = 'onset'][1]" mode="m_tei-to-yaml"/>
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>place: </xsl:text>
        <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/>
        <xsl:choose>
            <xsl:when test="$p_biblstruct/descendant::tei:placeName[parent::tei:pubPlace][@ref != 'NA']">
                <xsl:apply-templates select="$p_biblstruct/descendant::tei:placeName[parent::tei:pubPlace][@ref != 'NA'][1]" mode="m_tei-to-yaml"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$p_biblstruct/descendant::tei:placeName[parent::tei:pubPlace][1]" mode="m_tei-to-yaml"/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- IDs -->
        <xsl:value-of select="$v_new-line"/>
        <xsl:text>ids</xsl:text><xsl:value-of select="$v_key-value-sep"/>
        <xsl:for-each select="$p_biblstruct/tei:monogr/tei:idno">
            <xsl:sort select="@type" order="ascending" />
            <xsl:sort select="." order="ascending"/>
            <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/>
            <xsl:apply-templates select="." mode="m_tei-to-yaml"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:template match="text() | @*" mode="m_tei-to-yaml">
        <xsl:value-of select="$v_quot"/><xsl:value-of select="normalize-space(.)"/><xsl:value-of select="$v_quot"/>
    </xsl:template>
    
    <xsl:template match="tei:title" mode="m_tei-to-yaml">
        <xsl:text>- </xsl:text>
        <xsl:choose>
            <xsl:when test="@type = 'sub'">
                <xsl:text>subtitle</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>title</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$v_key-value-sep"/><xsl:apply-templates select="text()" mode="m_tei-to-yaml"/>
        <xsl:value-of select="$v_new-line"/>
        <!-- level of indention? -->
        <xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/>
        <xsl:text>lang</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:apply-templates select="@xml:lang" mode="m_tei-to-yaml"/>
    </xsl:template>
    <xsl:template match="tei:placeName" mode="m_tei-to-yaml">
        <xsl:choose>
            <xsl:when test="@ref != 'NA'">
                <xsl:variable name="v_name" select="oape:query-gazetteer(., $v_gazetteer, $p_local-authority, 'name', 'en')"/>
                <xsl:variable name="v_url-geon" select="oape:query-gazetteer(., $v_gazetteer, $p_local-authority, 'url-geon', '')"/>
                <xsl:text>- </xsl:text><xsl:text>name</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_name"/><xsl:value-of select="$v_quot"/>
                <xsl:if test="$v_url-geon != 'NA'">
                    <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/>
                    <xsl:text>GeoNames</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:value-of select="$v_url-geon"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="text()" mode="m_tei-to-yaml"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:idno" mode="m_tei-to-yaml">
        <xsl:text>- </xsl:text><xsl:value-of select="@type"/><xsl:value-of select="$v_key-value-sep"/>
        <xsl:value-of select="$v_quot"/>
        <xsl:value-of select="oape:resolve-id(.)"/>
        <xsl:value-of select="$v_quot"/>
    </xsl:template>
    <xsl:template match="tei:date" mode="m_tei-to-yaml">
        <xsl:choose>
            <xsl:when test="@when">
                <xsl:apply-templates select="@when" mode="m_tei-to-yaml"/>
            </xsl:when>
        <xsl:when test="@type = 'onset'">
        <xsl:choose>
            <xsl:when test="@notBefore">
                <xsl:apply-templates select="@notBefore" mode="m_tei-to-yaml"/>
            </xsl:when>
            <xsl:when test="@from">
                <xsl:apply-templates select="@from" mode="m_tei-to-yaml"/>
            </xsl:when>
        </xsl:choose>
        </xsl:when>
            <xsl:when test="@type = 'terminus'">
        <xsl:choose>
            <xsl:when test="@notAfter">
                <xsl:apply-templates select="@notAfter" mode="m_tei-to-yaml"/>
            </xsl:when>
            <xsl:when test="@to">
                <xsl:apply-templates select="@to" mode="m_tei-to-yaml"/>
            </xsl:when>
        </xsl:choose>
        </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:persName" mode="m_tei-to-yaml" priority="10">
        <xsl:text>- </xsl:text><xsl:text>name</xsl:text><xsl:value-of select="$v_key-value-sep"/>
        <xsl:choose>
            <xsl:when test="@ref != 'NA'">
                <xsl:variable name="v_name" select="oape:query-personography(., $v_personography, $p_local-authority, 'name', 'en')"/>
                <xsl:variable name="v_url-viaf" select="oape:query-personography(., $v_personography, $p_local-authority, 'url-viaf', '')"/>
                <xsl:variable name="v_url-wiki" select="oape:query-personography(., $v_personography, $p_local-authority, 'url-wiki', '')"/>
                <xsl:variable name="v_id-local" select="oape:query-personography(., $v_personography, $p_local-authority, 'id-local', '')"/>
                <xsl:value-of select="$v_quot"/><xsl:value-of select="$v_name"/><xsl:value-of select="$v_quot"/>
                <xsl:if test="$v_url-viaf != 'NA'">
                    <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/>
                    <xsl:text>VIAF</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_url-viaf"/><xsl:value-of select="$v_quot"/>
                </xsl:if>
                <xsl:if test="$v_url-wiki != 'NA'">
                    <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/>
                    <xsl:text>Wikidata</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_url-wiki"/><xsl:value-of select="$v_quot"/>
                </xsl:if>
                <xsl:if test="$v_id-local != 'NA'">
                    <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/>
                    <xsl:value-of select="$p_local-authority"/><xsl:value-of select="$v_key-value-sep"/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_id-local"/><xsl:value-of select="$v_quot"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="text()" mode="m_tei-to-yaml"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:author | tei:editor" mode="m_tei-to-yaml">
        <xsl:text>- </xsl:text><xsl:apply-templates select="text()" mode="m_tei-to-yaml"/><xsl:value-of select="$v_key-value-sep"/>
        <xsl:value-of select="$v_new-line"/>
        <!-- level of indention? -->
        <xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/>
        <xsl:text>lang</xsl:text><xsl:value-of select="$v_key-value-sep"/><xsl:apply-templates select="@xml:lang" mode="m_tei-to-yaml"/>
    </xsl:template>
    <xsl:template match="tei:persName" mode="m_tei-to-yaml">
        <xsl:value-of select="$v_new-line"/><xsl:value-of select="$v_tab"/><xsl:text>- </xsl:text>
        <xsl:choose>
            <xsl:when test="tei:surname">
                <xsl:apply-templates select="tei:surname" mode="m_tei-to-yaml"/>
                <xsl:apply-templates select="tei:forename" mode="m_tei-to-yaml"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$v_quot"/><xsl:apply-templates select="." mode="m_plain-text"/><xsl:value-of select="$v_quot"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:surname" mode="m_tei-to-yaml">
        <xsl:text>family: </xsl:text><xsl:value-of select="$v_quot"/><xsl:apply-templates select="." mode="m_plain-text"/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
    </xsl:template>
    <xsl:template match="tei:forename" mode="m_tei-to-yaml">
        <xsl:value-of select="$v_tab"/><xsl:value-of select="$v_tab"/><xsl:text>given: </xsl:text><xsl:value-of select="$v_quot"/><xsl:apply-templates select="." mode="m_plain-text"/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
    </xsl:template>
    
    <xsl:template match="tei:biblScope" mode="m_tei-to-yaml">
        <xsl:param name="p_indent"/>
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:value-of select="@unit"/><xsl:text>: </xsl:text>
        <xsl:value-of select="$v_quot"/>
        <xsl:choose>
            <xsl:when test="@from = @to">
                <xsl:value-of select="@from"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@from"/><xsl:text>-</xsl:text><xsl:value-of select="@to"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$v_quot"/>
    </xsl:template>
    
</xsl:stylesheet>