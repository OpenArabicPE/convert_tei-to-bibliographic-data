<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.loc.gov/mods/v3">
    <xsl:param name="p_target-language" select="'de'"/>
    <xsl:param name="p_github-action" select="false()"/>
    <xsl:param name="p_verbose" select="false()"/>
    <xsl:param name="p_debug" select="false()"/>
    <xsl:param name="p_mods-simple-persnames" select="false()"/>
    <xsl:param name="p_add-license" select="false()"/>
    <xsl:param name="p_stand-alone" select="false()"/>
    <xsl:variable name="v_license" select="'http://creativecommons.org/licenses/by-sa/4.0/'"/>
    <xsl:variable name="v_license-url" select="'http://creativecommons.org/licenses/by-sa/4.0/'"/>
    <xsl:param name="p_detect-language-from-title" select="false()"/>
    <!-- authorities -->
    <xsl:param name="p_acronym-geonames" select="'geon'"/> <!-- in WHG this is 'gn' -->
    <xsl:param name="p_acronym-viaf" select="'viaf'"/>
    <xsl:param name="p_acronym-wikidata" select="'wiki'"/> <!-- in WHG this is 'wd' -->
    <xsl:param name="p_acronym-wikimapia" select="'lwm'"/>
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:param name="p_id-editor" select="'pers_TG'"/>
    <xsl:param name="p_id-change" select="generate-id(//tei:revisionDesc[1]/tei:change[last()])"/>
    <xsl:variable name="v_base-directory">
        <xsl:choose>
            <xsl:when test="$p_github-action = true()"/>
            <xsl:when test="$p_github-action = false()">
                <xsl:value-of select="'../'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:param name="p_today-iso" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
    <xsl:variable name="vgFileId" select="substring-before(tokenize(base-uri(), '/')[last()], '.TEIP5')"/>
    <xsl:variable name="v_file-name_input">
        <xsl:variable name="v_temp" select="tokenize(base-uri(), '/')[last()]"/>
        <xsl:value-of select="replace($v_temp, '^(.+?)(\.(MODS|TEIP5))*?(\.(xml|mrx|mrcx))$', '$1')"/>
    </xsl:variable>
    <!-- file IDs -->
    <xsl:variable name="v_id-file" select="
            if (tei:TEI/@xml:id) then
                (tei:TEI/@xml:id)
            else
                (substring-before(tokenize(base-uri(), '/')[last()], '.TEIP5'))"/>
    <xsl:variable name="v_url-file" select="base-uri()"/>
    <xsl:variable name="v_path-source">
        <xsl:choose>
              <!-- relative local path for my current set-up  -->
             <xsl:when test="matches(base-uri(), 'file:/Users/Shared/BachUni/BachBibliothek/GitHub/')">
                 <xsl:value-of select="replace(base-uri(), 'file:/Users/Shared/BachUni/BachBibliothek/GitHub/', '../../../../')"/>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:value-of select="base-uri()"/>
             </xsl:otherwise>
         </xsl:choose>
    </xsl:variable>
    <xsl:variable name="v_url-base" select="replace($v_url-file, '^(.+)/([^/]+?)$', '$1')"/>
    <xsl:param name="p_output-folder" select="concat($v_base-directory,'metadata/')"/>
    <!-- URLs -->
    <xsl:variable name="v_url-server-zdb-ld" select="'https://ld.zdb-services.de/data/'"/>
    <xsl:variable name="v_url-gnd-resolve" select="'https://d-nb.info/gnd/'"/>
    <!-- strings -->
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_quot" select="'&quot;'"/>
    <xsl:variable name="v_comma" select="','"/>
    <xsl:variable name="v_tab" select="'&#0009;'"/>
    <xsl:variable name="v_space" select="' '"/>
    <xsl:variable name="v_seperator-qs" select="'|'"/>
</xsl:stylesheet>
