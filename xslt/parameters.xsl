<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.loc.gov/mods/v3">

    <xsl:param name="p_target-language" select="'ar'"/>
    
    <xsl:param name="p_github-action" select="false()"/>
    
    <xsl:variable name="v_base-directory">
        <xsl:choose>
            <xsl:when test="$p_github-action = true()"/>
            <xsl:when test="$p_github-action = false()">
                <xsl:value-of select="'../'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="vgFileId" select="substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5')"/>
    <xsl:variable name="v_file-name_input">
        <xsl:variable name="v_temp" select="tokenize(base-uri(), '/')[last()]"/>
        <xsl:value-of select="replace($v_temp, '^(.+?)(\..*)*$', '$1')"/>
    </xsl:variable>
    <!-- file IDs -->
    <xsl:variable name="v_id-file" select="if(tei:TEI/@xml:id) then(tei:TEI/@xml:id) else(substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5'))"/>
    <xsl:variable name="v_url-file" select="base-uri()"/>
    <xsl:variable name="v_url-base" select="replace($v_url-file, '^(.+)/([^/]+?)$', '$1')"/>
</xsl:stylesheet>