<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs" version="3.0" 
    xmlns:mets="http://www.loc.gov/METS/" 
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <xsl:import href="convert_tei-to-mods_functions.xsl"/>
    
    <xsl:template match="/">
        <xsl:element name="mets:mets">
            <!-- header: metadata about the METS file -->
            <xsl:element name="mets:metsHdr"/>
            <!-- descriptive metadata: MODS etc. -->
            <xsl:element name="mets:dmdSec">
                <xsl:element name="mets:mdWrap">
                    <xsl:element name="mets:xmlData">
                        <!-- XML from another namespace, such as MODS -->
                        <xsl:copy-of select="oape:bibliography-tei-to-mods(descendant-or-self::tei:sourceDesc/tei:biblStruct, 'ar')"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
            <!-- administrative metadata: copyright etc. -->
            <xsl:element name="mets:amdSec"/>
            <!-- component files -->
            <xsl:element name="mets:fileSec">
                <!-- facsimiles -->
                <xsl:copy-of select="oape:file-tei-to-mets-facsimiles(descendant::tei:facsimile)"/>
                <!-- text layers -->
            </xsl:element>
            <!-- structMap: connecting the various layers -->
            <xsl:element name="mets:structMap">
                
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:function name="oape:file-tei-to-mets-facsimiles">
        <xsl:param name="p_facsimile" as="node()"/>
         <xsl:element name="mets:fileGrp">
            <xsl:attribute name="ID" select="'IMG'"/>
            <xsl:apply-templates select="$p_facsimile/tei:surface" mode="m_tei-to-mets"/>
        </xsl:element>
    </xsl:function>
    <xsl:template match="tei:surface" mode="m_tei-to-mets">
        <!-- select one file per surface -->
        <xsl:apply-templates select="tei:graphic[matches(@url, '^http')][1]" mode="m_tei-to-mets"/>
    </xsl:template>
    <xsl:template match="tei:graphic" mode="m_tei-to-mets">
        <xsl:variable name="v_position" select="count(parent::tei:surface/preceding-sibling::tei:surface) + 1"/>
        <xsl:element name="mets:file">
            <xsl:attribute name="ID" select="concat('IMG_', $v_position)"/>
            <xsl:attribute name="SEQ" select="$v_position"/>
            <xsl:attribute name="MIMETYPE" select="@mimeType"/>
            <!-- file -->
            <xsl:element name="mets:FLocat">
                <xsl:attribute name="LOCTYPE" select="'OTHER'"/>
                <xsl:attribute name="OTHERLOCTYPE" select="'FILE'"/>
                <xsl:attribute name="xlink:href" select="@url"/>
                <xsl:attribute name="xlink:type" select="'simple'"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
