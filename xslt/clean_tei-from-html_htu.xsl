<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:ckbk="http://www.ora.com/XSLTCookbook/math" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:31'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <xsl:template match="tei:date[contains(., '/')]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="type" select="'onset'"/>
            <xsl:value-of select="substring-before(., '/')"/>
        </xsl:copy>
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="type" select="'terminus'"/>
            <xsl:value-of select="substring-after(., '/')"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblScope[matches(., '^\d+(\.\s+)*defa\s*$')]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="unit" select="'volume'"/>
            <xsl:attribute name="from" select="replace(., '^(\d+)(\.\s+)*defa\s*$', '$1')"/>
            <xsl:attribute name="to" select="replace(., '^(\d+)(\.\s+)*defa\s*$', '$1')"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[@when &lt; 1700]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@change | @type"/>
            <xsl:attribute name="datingMethod" select="'#cal_ottomanfiscal'"/>
            <xsl:attribute name="when-custom" select="@when"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[@datingMethod][text()]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="calendar" select="@datingMethod"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblScope[not(@unit)]" mode="m_off" priority="20">
        <xsl:choose>
            <!-- ranges of volumes and issues: split -->
            <xsl:when test="matches(., '^\s*([I|V|X]+)\s*(.*)-\s*([I|V|X]+)\s*(.*)$')">
                <bibl type="copy">
                    <xsl:copy>
                        <xsl:apply-templates mode="m_post-process" select="@*"/>
                        <xsl:value-of select="replace(., '^\s*([I|V|X]+\s*.*)-\s*([I|V|X]+\s*.*)$', '$1')"/>
                    </xsl:copy>
                </bibl>
                <bibl type="copy">
                    <xsl:copy>
                        <xsl:apply-templates mode="m_post-process" select="@*"/>
                        <xsl:value-of select="replace(., '^\s*([I|V|X]+\s*.*)-\s*([I|V|X]+\s*.*)$', '$2')"/>
                    </xsl:copy>
                </bibl>
            </xsl:when>
            <xsl:when test="matches(., '^\s*([I|V|X]+)\s*:\s*(.*)$')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:attribute name="unit" select="'volume'"/>
                    <xsl:value-of select="replace(., '^\s*([I|V|X]+)\s*:\s*(.*)$', '$1')"/>
                </xsl:copy>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@*"/>
                    <xsl:value-of select="replace(., '^\s*([I|V|X]+)\s*:\s*(.*)$', '$2')"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- this doesn't work at all -->
    <xsl:template match="tei:biblScope[@unit = 'volume']" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:copy-of select="oape:translate-roman-numerals(.)"/>
            <!-- <xsl:variable name="v_value" select="ckbk:roman-to-number(.)"/>
            <xsl:message terminate="yes">
                <xsl:value-of select="$v_value"/>
            </xsl:message>
            <xsl:if test="$v_value != ''">
                <xsl:attribute name="from" select="$v_value"/>
                <xsl:attribute name="to" select="$v_value"/>
                <xsl:value-of select="$v_value"/>
            </xsl:if>-->
        </xsl:copy>
    </xsl:template>
    <xsl:function name="oape:translate-roman-numerals">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_nummeric">
            <xsl:call-template name="t_replace-roman-numerals">
                <xsl:with-param name="p_input" select="$p_input"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:message terminate="yes">
            <xsl:value-of select="$v_nummeric"/>
        </xsl:message>
    </xsl:function>
    <xsl:template name="t_replace-roman-numerals">
        <xsl:param name="p_input"/>
        <xsl:param name="p_add" select="true()"/>
        <xsl:param name="p_value" select="0"/>
        <xsl:variable name="v_value-first-letter" select="replace($v_numerals, concat('^.*;', substring($p_input, 1, 1), '=(\d+);.*$'), '$1', 'i')"/>
        <xsl:variable name="v_value-next-letter" select="replace($v_numerals, concat('^.*;', substring($p_input, 2, 1), '=(\d+);.*$'), '$1', 'i')"/>
        <xsl:choose>
            <xsl:when test="string-length($p_input) > 1">
                <xsl:call-template name="t_replace-roman-numerals">
                    <xsl:with-param name="p_input" select="substring($p_input, 2)"/>
                    <xsl:with-param name="p_add" select="
                            if ($v_value-first-letter &gt;= $v_value-next-letter) then
                                (true())
                            else
                                (false())"/>
                    <xsl:with-param name="p_value" select="
                            if ($p_add = true()) then
                                ($p_value + $v_value-first-letter)
                            else
                                ()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$p_value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:variable name="v_numerals">
        <num value="1">I</num>
        <num value="10">X</num>
        <num value="11">XI</num>
        <num value="12">XII</num>
        <num value="13">XIII</num>
        <num value="14">XIV</num>
        <num value="15">XV</num>
        <num value="16">XVI</num>
        <num value="17">XVII</num>
        <num value="18">XVIII</num>
        <num value="19">XIX</num>
        <num value="2">II</num>
        <num value="20">XX</num>
        <num value="21">XXI</num>
        <num value="22">XXII</num>
        <num value="23">XXIII</num>
        <num value="24">XXIV</num>
        <num value="25">XXV</num>
        <num value="26">XXVI</num>
        <num value="27">XXVII</num>
        <num value="28">XXVIII</num>
        <num value="29">XXIX</num>
        <num value="3">III</num>
        <num value="30">XXX</num>
        <num value="31">XXXI</num>
        <num value="32">XXXII</num>
        <num value="33">XXXIII</num>
        <num value="34">XXXIV</num>
        <num value="35">XXXV</num>
        <num value="36">XXXVI</num>
        <num value="37">XXXVII</num>
        <num value="38">XXXVIII</num>
        <num value="39">XXXIX</num>
        <num value="4">IV</num>
        <num value="5">V</num>
        <num value="6">VI</num>
        <num value="7">VII</num>
        <num value="8">VIII</num>
        <num value="9">IX</num>
<!--        <xsl:text>;i=1;v=5;x=10;l=50;c=100;d=500;m=1000;</xsl:text>-->
    </xsl:variable>
    <xsl:variable name="ckbk:roman-nums">
        <ckbk:roman value="1">i</ckbk:roman>
        <ckbk:roman value="1">I</ckbk:roman>
        <ckbk:roman value="5">v</ckbk:roman>
        <ckbk:roman value="5">V</ckbk:roman>
        <ckbk:roman value="10">x</ckbk:roman>
        <ckbk:roman value="10">X</ckbk:roman>
        <ckbk:roman value="50">l</ckbk:roman>
        <ckbk:roman value="50">L</ckbk:roman>
        <ckbk:roman value="100">c</ckbk:roman>
        <ckbk:roman value="100">C</ckbk:roman>
        <ckbk:roman value="500">d</ckbk:roman>
        <ckbk:roman value="500">D</ckbk:roman>
        <ckbk:roman value="1000">m</ckbk:roman>
        <ckbk:roman value="1000">M</ckbk:roman>
    </xsl:variable>
    <xsl:function name="ckbk:roman-to-number">
        <xsl:param name="roman"/>
        <xsl:variable name="valid-roman-chars">
            <xsl:value-of select="$ckbk:roman-nums/ckbk:roman"/>
        </xsl:variable>
        <xsl:choose>
            <!-- returns true if there are any non-Roman characters in the string -->
            <xsl:when test="translate($roman, $valid-roman-chars, '')">NN</xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ckbk:roman-to-number-impl">
                    <xsl:with-param name="roman" select="$roman"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template name="ckbk:roman-to-number-impl">
        <xsl:param name="roman"/>
        <xsl:param name="value" select="0"/>
        <xsl:variable name="len" select="string-length($roman)"/>
        <xsl:choose>
            <xsl:when test="not($len)">
                <xsl:value-of select="$value"/>
            </xsl:when>
            <xsl:when test="$len = 1">
                <xsl:value-of select="$value + $ckbk:roman-nums[. = $roman]/@value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="roman-num" select="$ckbk:roman-nums[. = substring($roman, 1, 1)]"/>
                <xsl:choose>
                    <xsl:when test="$roman-num/following-sibling::ckbk:roman = substring($roman, 2, 1)">
                        <xsl:call-template name="ckbk:roman-to-number-impl">
                            <xsl:with-param name="roman" select="substring($roman, 2, $len - 1)"/>
                            <xsl:with-param name="value" select="$value - $roman-num/@value"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="ckbk:roman-to-number-impl">
                            <xsl:with-param name="roman" select="substring($roman, 2, $len - 1)"/>
                            <xsl:with-param name="value" select="$value + $roman-num/@value"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
