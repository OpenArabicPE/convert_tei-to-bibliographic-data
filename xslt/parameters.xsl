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
</xsl:stylesheet>