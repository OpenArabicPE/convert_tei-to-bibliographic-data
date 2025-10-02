<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
   
    
    <!-- remove all orgs which are already part of the organizationography -->
    <xsl:template match="tei:org[parent::tei:listOrg][tei:orgName[@ref]]" mode="m_off"/>
    <!-- dates-->
    <xsl:template match="tei:idno[@type = 'zdb'][starts-with(.,'ZDB')]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="substring-after(., 'ZDB')"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
