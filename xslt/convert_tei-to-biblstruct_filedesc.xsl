<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:cc="http://web.resource.org/cc/"  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}metadata/file/{$v_id-file}.TEIP5.xml" method="xml">
      <TEI>
          <teiHeader>
              <fileDesc></fileDesc>
          </teiHeader>
          <standOff>
              <listBibl>
                  <xsl:apply-templates mode="m_fileDesc-to-biblStruct" select="tei:TEI/tei:teiHeader/tei:fileDesc"/> 
              </listBibl>
          </standOff>
      </TEI>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
