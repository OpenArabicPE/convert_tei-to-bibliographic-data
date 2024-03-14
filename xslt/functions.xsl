<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:bib="http://purl.org/net/biblio#" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:link="http://purl.org/rss/1.0/modules/link/"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:vcard="http://nwalsh.com/rdf/vCard#" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:z="http://www.zotero.org/namespaces/export#">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
    <xsl:import href="parameters.xsl"/>
    <xsl:function name="oape:string-convert-lang-codes">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:param name="p_source-encoding"/>
        <xsl:param name="p_target-encoding"/>
        <xsl:variable name="v_iso639-2_bcp47"
            >;aar=aa;abk=ab;afr=af;aka=ak;amh=am;ara=ar;arg=an;asm=as;ava=av;ave=ae;aym=ay;aze=az;bak=ba;bam=bm;bel=be;ben=bn;bis=bi;tib=bo;bos=bs;bre=br;bul=bg;cat=ca;cze=cs;cha=ch;che=ce;chu=cu;chv=cv;cor=kw;cos=co;cre=cr;wel=cy;dan=da;ger=de;div=dv;dzo=dz;gre=el;eng=en;epo=eo;est=et;baq=eu;ewe=ee;fao=fo;per=fa;fij=fj;fin=fi;fre=fr;fry=fy;ful=ff;gla=gd;gle=ga;glg=gl;glv=gv;grn=gn;guj=gu;hat=ht;hau=ha;=sh;heb=he;her=hz;hin=hi;hmo=ho;hrv=hr;hun=hu;arm=hy;ibo=ig;ido=io;iii=ii;iku=iu;ile=ie;ina=ia;ind=id;ipk=ik;ice=is;ita=it;jav=jv;jpn=ja;kal=kl;kan=kn;kas=ks;geo=ka;kau=kr;kaz=kk;khm=km;kik=ki;kin=rw;kir=ky;kom=kv;kon=kg;kor=ko;kua=kj;kur=ku;lao=lo;lat=la;lav=lv;lim=li;lin=ln;lit=lt;ltz=lb;lub=lu;lug=lg;mah=mh;mal=ml;mar=mr;mac=mk;mlg=mg;mlt=mt;mon=mn;mao=mi;may=ms;bur=my;nau=na;nav=nv;nbl=nr;nde=nd;ndo=ng;nep=ne;dut=nl;nno=nn;nob=nb;nor=no;nya=ny;oci=oc;oji=oj;ori=or;orm=om;oss=os;pan=pa;pli=pi;pol=pl;por=pt;pus=ps;que=qu;roh=rm;rum=ro;run=rn;rus=ru;sag=sg;san=sa;sin=si;slo=sk;slv=sl;sme=se;smo=sm;sna=sn;snd=sd;som=so;sot=st;spa=es;alb=sq;srd=sc;srp=sr;ssw=ss;sun=su;swa=sw;swe=sv;tah=ty;tam=ta;tat=tt;tel=te;tgk=tg;tgl=tl;tha=th;tir=ti;ton=to;tsn=tn;tso=ts;tuk=tk;tur=tr;twi=tw;uig=ug;ukr=uk;urd=ur;uzb=uz;ven=ve;vie=vi;vol=vo;wln=wa;wol=wo;xho=xh;yid=yi;yor=yo;zha=za;chi=zh;zul=zu</xsl:variable>
        <xsl:variable name="v_bcp47_wikidata"
            >;ar=Q13955;arz=Q29919;cop=Q36155;de=Q188;en=Q1860;es=Q1321;fa=Q9168;fr=Q150;gr=Q9129;he=Q9288;hy=Q8785;it=Q652;jrb=Q37733;la=Q397;lad=Q36196;ota=Q36730;ps=Q58680;pt=Q5146;ru=Q7737;syc=Q33538;tr=Q256;ur=Q1617;zh=Q7850</xsl:variable>
        <xsl:choose>
            <xsl:when test="$p_source-encoding = 'iso639-2' and $p_target-encoding = 'bcp47'">
                <xsl:value-of select="replace($v_iso639-2_bcp47, concat('^.*;', $p_input, '=(\w{2});.*$'), '$1')"/>
            </xsl:when>
            <xsl:when test="$p_source-encoding = 'bcp47' and $p_target-encoding = 'iso639-2' and matches($v_iso639-2_bcp47, concat('=', $p_input))">
                <xsl:value-of select="replace($v_iso639-2_bcp47, concat('^.*;(\w{3})=', $p_input, ';.*$'), '$1')"/>
            </xsl:when>
            <xsl:when test="$p_source-encoding = 'bcp47' and $p_target-encoding = 'wikidata' and matches($v_bcp47_wikidata, concat(';', $p_input, '='))">
                <xsl:value-of select="replace($v_bcp47_wikidata, concat('^.*;', $p_input, '=(Q\d+);.*$'), '$1')"/>
            </xsl:when>
            <xsl:when test="$p_source-encoding = 'wikidata' and $p_target-encoding = 'bcp47'">
                <xsl:value-of select="replace($v_iso639-2_bcp47, concat('^.*;(\w{2})=', $p_input, ';.*$'), '$1')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'NA'"/>
                <xsl:message>
                    <xsl:text>FAILURE: Combination of language encodings not supported</xsl:text>
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="$p_input"/>
                    <xsl:text>|</xsl:text>
                    <xsl:value-of select="$p_source-encoding"/>
                    <xsl:text>|</xsl:text>
                    <xsl:value-of select="$p_target-encoding"/>
                    <xsl:text>)</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- plain text output   -->
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <!-- add template for persName -->
    <xsl:template match="tei:persName" mode="m_plain-text" priority="2">
        <xsl:variable name="v_temp">
            <xsl:apply-templates mode="m_plain-text"/>
        </xsl:variable>
        <xsl:value-of select="normalize-space($v_temp)"/>
    </xsl:template>
    <xsl:template match="element()[ancestor::tei:persName]" mode="m_plain-text" priority="2">
        <xsl:text> </xsl:text>
        <xsl:apply-templates mode="m_plain-text"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="element()" mode="m_plain-text">
        <xsl:apply-templates mode="m_plain-text"/>
    </xsl:template>
    <xsl:template match="text()[matches(., '^\s+$')]" mode="m_plain-text" priority="10"/>
    <xsl:template match="text()" mode="m_plain-text">
        <!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <xsl:template match="text()[not(ancestor::tei:choice)][preceding-sibling::node()]" mode="m_plain-text">
        <xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <!--<xsl:template match="text()[not(ancestor::tei:choice)][following-sibling::node()]" mode="m_plain-text">
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text> </xsl:text>
    </xsl:template>-->
    <!-- choice -->
    <xsl:template match="tei:choice" mode="m_plain-text">
        <xsl:choose>
            <xsl:when test="tei:abbr and tei:expan">
                <xsl:apply-templates mode="m_plain-text" select="tei:expan"/>
            </xsl:when>
            <xsl:when test="tei:orig">
                <xsl:apply-templates mode="m_plain-text" select="tei:orig"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- replace any line, column or page break with a single whitespace -->
    <xsl:template match="tei:lb | tei:cb | tei:pb" mode="m_plain-text">
        <xsl:text> </xsl:text>
    </xsl:template>
    <!-- prevent notes in div/head from producing output -->
    <xsl:template match="tei:head/tei:note" mode="m_plain-text" priority="100"/>
    <!-- trim trailing and leading punctuation marks -->
    <xsl:function name="oape:strings_trim-punctuation-marks">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:variable name="v_punctuation" select="'[,،\.:;\?!\-–—_/]'"/>
        <xsl:analyze-string regex="^{$v_punctuation}*\s*(.+)\s*{$v_punctuation}$" select="$p_input">
            <xsl:matching-substring>
                <xsl:value-of select="normalize-space(regex-group(1))"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    <xsl:template match="tei:bibl" mode="m_bibl-to-biblStruct">
        <xsl:variable name="v_source">
            <xsl:choose>
                <xsl:when test="@source">
                    <!-- base-uri() is relative to the current context. if the <bibl> was generated by XSLT, this will be the context -->
                    <xsl:value-of select="concat(@source, ' ', $v_url-file, '#', @xml:id)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($v_url-file, '#', @xml:id)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- publication date of the source file -->
        <xsl:variable name="v_source-date" select="document($v_url-file)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/descendant::tei:biblStruct[1]/descendant::tei:date[@when][1]/@when"/>
        <biblStruct>
            <xsl:apply-templates mode="m_copy-from-source" select="@*"/>
            <!-- document source of information -->
            <xsl:attribute name="source" select="$v_source"/>
            <xsl:if test="tei:title[@level = 'a']">
                <analytic>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:title[@level = 'a']"/>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:author"/>
                </analytic>
            </xsl:if>
            <monogr>
                <xsl:apply-templates mode="m_copy-from-source" select="tei:title[@level != 'a']"/>
                <xsl:apply-templates mode="m_copy-from-source" select="tei:idno"/>
                <xsl:for-each select="tokenize(tei:title[@level != 'a'][@ref][1]/@ref, '\s+')">
                    <xsl:variable name="v_authority">
                        <xsl:choose>
                            <xsl:when test="contains(., 'oclc:')">
                                <xsl:text>OCLC</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(., 'jaraid:')">
                                <xsl:text>jaraid</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(., 'oape:')">
                                <xsl:text>oape</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="v_local-uri-scheme" select="concat($v_authority, ':bibl:')"/>
                    <xsl:variable name="v_idno">
                        <xsl:choose>
                            <xsl:when test="contains(., 'oclc:')">
                                <xsl:value-of select="replace(., '.*oclc:(\d+).*', '$1')"/>
                            </xsl:when>
                            <xsl:when test="contains(., $v_local-uri-scheme)">
                                <!-- local IDs in Project Jaraid are not nummeric for biblStructs -->
                                <xsl:value-of select="replace(., concat('.*', $v_local-uri-scheme, '(\w+).*'), '$1')"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <idno type="{$v_authority}">
                        <xsl:value-of select="$v_idno"/>
                    </idno>
                </xsl:for-each>
                <xsl:choose>
                    <xsl:when test="tei:textLang">
                        <xsl:apply-templates mode="m_copy-from-source" select="tei:textLang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <textLang>
                            <xsl:attribute name="mainLang">
                                <xsl:choose>
                                    <xsl:when test="tei:title[@level != 'a']/@xml:lang">
                                        <xsl:value-of select="tei:title[@level != 'a'][@xml:lang][1]/@xml:lang"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>ar</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </textLang>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="tei:title[@level != 'a']">
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:author"/>
                </xsl:if>
                <xsl:apply-templates mode="m_copy-from-source" select="tei:editor"/>
                <imprint>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:date"/>
                    <!-- add a date at which this bibl was documented in the source file -->
                    <xsl:if test="empty($v_source-date) = false()">
                        <date type="documented" when="{$v_source-date}"/>
                    </xsl:if>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:pubPlace"/>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:publisher"/>
                </imprint>
                <xsl:apply-templates mode="m_copy-from-source" select="tei:biblScope"/>
            </monogr>
        </biblStruct>
    </xsl:template>
    <!-- do not copy certain attributes from one file to another -->
    <xsl:template match="@xml:id | @change | @next | @prev" mode="m_copy-from-source"/>
    <xsl:template match="node() | @*" mode="m_copy-from-source">
        <xsl:copy>
            <xsl:apply-templates mode="m_copy-from-source" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="text()" mode="m_copy-from-source" priority="10">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
</xsl:stylesheet>
