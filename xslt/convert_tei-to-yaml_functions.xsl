<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <xsl:output method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" name="text"/>
    <xsl:strip-space elements="*"/>
    
    <!-- this stylesheet translates <tei:biblStruct>s to  YAML -->
    
    <!-- toggle debugging messages -->
<!--    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>-->
    
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_quot" select="'&apos;''"/>
    <xsl:variable name="v_comma" select="','"/>
    <xsl:variable name="v_tab" select="'  '"/>
    
    <!-- testing -->
    <!--<xsl:template match="/">
        <xsl:apply-templates select="descendant::tei:biblStruct" mode="m_tei-to-yaml"/>
    </xsl:template>-->  
    <xsl:template match="tei:biblStruct" mode="m_tei-to-yaml">
        <xsl:copy-of select="oape:bibliography-tei-to-yaml(., 'ar', false())"/>
    </xsl:template>
    
    <xsl:function name="oape:bibliography-tei-to-yaml">
        <xsl:param name="p_input"/>
        <xsl:param name="p_lang"/>
        <!-- param to select wether a YAML block should be part of a list or independent -->
        <xsl:param name="p_indent"/>
        <xsl:variable name="v_title-analytic">
            <xsl:value-of select="$v_quot"/>
            <xsl:choose>
                <xsl:when test="$p_input/tei:analytic/tei:title[@level = 'a'][@xml:lang = $p_lang]">
                    <xsl:value-of select="$p_input/tei:analytic/tei:title[@level = 'a'][@xml:lang = $p_lang][1]"/>
                </xsl:when>
                <xsl:when test="$p_input/tei:analytic/tei:title[@level = 'a']">
                    <xsl:value-of select="$p_input/tei:analytic/tei:title[@level = 'a'][1]"/>
                </xsl:when>
            </xsl:choose>
            <xsl:value-of select="$v_quot"/>
        </xsl:variable> 
         <xsl:variable name="v_title-monogr">
            <xsl:value-of select="$v_quot"/>
            <xsl:choose>
                <xsl:when test="$p_input/tei:monogr/tei:title[@level = 'j'][@xml:lang = $p_lang]">
                    <xsl:apply-templates select="$p_input/tei:monogr/tei:title[@level = 'j'][@xml:lang = $p_lang][1]" mode="m_plain-text"/>
                </xsl:when>
                <xsl:when test="$p_input/tei:monogr/tei:title[@level = 'j']">
                    <xsl:apply-templates select="$p_input/tei:monogr/tei:title[@level = 'j'][1]" mode="m_plain-text"/>
                </xsl:when>
            </xsl:choose>
             <!-- sub title -->
             <xsl:if test="$p_input/tei:monogr/tei:title[@level='j'][@type='sub']">
                <xsl:text>: </xsl:text>
                 <xsl:choose>
                <xsl:when test="$p_input/tei:monogr/tei:title[@level = 'j'][@type='sub'][@xml:lang = $p_lang]">
                    <xsl:apply-templates select="$p_input/tei:monogr/tei:title[@level = 'j'][@type='sub'][@xml:lang = $p_lang][1]" mode="m_plain-text"/>
                </xsl:when>
                <xsl:when test="$p_input/tei:monogr/tei:title[@level = 'j'][@type='sub']">
                    <xsl:apply-templates select="$p_input/tei:monogr/tei:title[@level = 'j'][@type='sub'][1]" mode="m_plain-text"/>
                </xsl:when>
            </xsl:choose>
             </xsl:if>
            <xsl:value-of select="$v_quot"/>
        </xsl:variable> 
        <!-- output -->
        <xsl:if test="$p_indent = true()"><xsl:text>- </xsl:text></xsl:if>
        <xsl:text>id: </xsl:text><xsl:value-of select="$v_quot"/><xsl:value-of select="$p_input/tei:analytic/tei:idno[@type='BibTeX']"/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
        <!-- titles -->
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>title: </xsl:text>
            <xsl:value-of select="$v_title-analytic"/><xsl:value-of select="$v_new-line"/>
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>container-title: </xsl:text>
            <xsl:value-of select="$v_title-monogr"/><xsl:value-of select="$v_new-line"/>
        <!-- volume, issue, pages -->
        <xsl:apply-templates select="$p_input/tei:monogr/tei:biblScope" mode="m_tei-to-yaml">
            <xsl:with-param name="p_indent" select="$p_indent"/>
        </xsl:apply-templates>
        <!-- IDs -->
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>URL: </xsl:text><xsl:value-of select="$v_new-line"/>
        <xsl:apply-templates select="$p_input/tei:analytic/tei:idno[@type='url']" mode="m_tei-to-yaml"/>
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>OCLC: </xsl:text><xsl:value-of select="$v_new-line"/>
        <xsl:apply-templates select="$p_input/tei:monogr/tei:idno[@type='OCLC']" mode="m_tei-to-yaml"/>
        <!-- author, editor -->
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>author: </xsl:text>
        <xsl:apply-templates select="$p_input/tei:analytic/tei:author" mode="m_tei-to-yaml">
            <xsl:with-param name="p_lang" select="$p_lang"/>
        </xsl:apply-templates>
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>editor: </xsl:text>
        <xsl:apply-templates select="$p_input/tei:monogr/tei:editor" mode="m_tei-to-yaml">
            <xsl:with-param name="p_lang" select="$p_lang"/>
        </xsl:apply-templates>
        <!-- language -->
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>language: </xsl:text><xsl:value-of select="$p_input/tei:monogr/tei:textLang/@mainLang"/><xsl:value-of select="$v_new-line"/>
        <!-- imprint  -->
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>type: </xsl:text><xsl:value-of select="$v_new-line"/>
  <!-- dates -->
        <xsl:if test="$p_indent = true()"><xsl:value-of select="$v_tab"/></xsl:if><xsl:text>issued: </xsl:text><xsl:apply-templates select="$p_input/tei:monogr/tei:imprint/tei:date[@when][1]" mode="m_tei-to-yaml"/><xsl:value-of select="$v_new-line"/>
    </xsl:function>
    <xsl:template match="tei:idno" mode="m_tei-to-yaml">
        <xsl:value-of select="$v_tab"/><xsl:text>- </xsl:text><xsl:value-of select="$v_quot"/><xsl:value-of select="."/><xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
    </xsl:template>
    <xsl:template match="tei:date[@when]" mode="m_tei-to-yaml">
        <xsl:value-of select="$v_quot"/>
        <xsl:value-of select="@when"/>
        <xsl:value-of select="$v_quot"/>
    </xsl:template>
    <xsl:template match="tei:author | tei:editor" mode="m_tei-to-yaml">
        <xsl:param name="p_lang"/>
        <xsl:apply-templates select="if(tei:persName[@xml:lang = $p_lang]) then(tei:persName[@xml:lang = $p_lang][1]) else(tei:persName[1])" mode="m_tei-to-yaml"/><xsl:value-of select="$v_new-line"/>
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
        <xsl:value-of select="$v_new-line"/>
    </xsl:template>
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_plain-text">
<!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
<!--        <xsl:text> </xsl:text>-->
        <xsl:value-of select="normalize-space(.)"/>
<!--        <xsl:text> </xsl:text>-->
    </xsl:template>
    
</xsl:stylesheet>