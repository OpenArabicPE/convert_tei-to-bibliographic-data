<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet translates <mods:mods> to <tei:biblStruct> -->
    
    <!-- debugging -->
    <xsl:template match="/">
        
    </xsl:template>
    <xsl:function name="oape:bibliography-mods-to-tei">
</xsl:stylesheet>