<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:zot="https://zotero.org"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet translates <mods:mods> to <tei:biblStruct> -->
    
    <xsl:include href="convert_mods-to-tei_functions.xsl"/>
    
    <!-- debugging -->
    <xsl:template match="/">
        <xsl:result-document href="{substring-before(base-uri(.),'.')}.TEIP5.xml">
            <TEI xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:copy-of select="$v_teiHeader"/>
                <text>
                   <body>
                       <div>
                            <listBibl>
                                <xsl:apply-templates select="descendant::mods:mods" mode="m_mods-to-tei"/>
                            </listBibl>
                       </div>
                   </body>
                </text>
            </TEI>
        </xsl:result-document>
    </xsl:template>
    <xsl:template match="mods:mods" mode="m_mods-to-tei">
        <xsl:copy-of select="oape:bibliography-mods-to-tei(.)"/>
    </xsl:template>
    <xsl:variable name="v_teiHeader">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>Title</title>
                </titleStmt>
                <publicationStmt>
                    <p>Publication Information</p>
                </publicationStmt>
                <sourceDesc>
                    <p>Information about the source</p>
                </sourceDesc>
            </fileDesc>
        </teiHeader>
    </xsl:variable>
</xsl:stylesheet>