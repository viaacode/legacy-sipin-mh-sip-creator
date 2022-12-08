<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:premis="http://www.loc.gov/premis/v3"
    xmlns:schema="http://schema.org/"
    xmlns:mhs="https://zeticon.mediahaven.com/metadata/22.1/mhs/"
    xmlns:mh="https://zeticon.mediahaven.com/metadata/22.1/mh/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ebucore="urn:ebu:metadata-schema:ebucore" exclude-result-prefixes="dc premis dcterms xsi schema ebucore" version="1.1">
    <xsl:output version="1.0" encoding="UTF-8" standalone="yes" indent="yes" />
    <xsl:param name="cp_name" />
    <xsl:param name="cp_id" />
    <xsl:param name="pid" />
    <xsl:param name="original_filename" />
    <xsl:param name="md5" />
    <xsl:param name="premis_path" />
    <xsl:param name="batch_id" />
    <xsl:param name="meemoo_workflow" />

    <xsl:variable name="premis_source" select="document($premis_path)/premis:premis" />
    <xsl:variable name="sp_name">
        <xsl:choose>
            <xsl:when test="$meemoo_workflow">
                <xsl:value-of select="$meemoo_workflow" />
            </xsl:when>
            <xsl:when test="$premis_source/premis:agent/premis:agentType[text()='SP Agent']">
                <xsl:value-of select="$premis_source/premis:agent[premis:agentType/text()='SP Agent']/premis:agentName/text()" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'borndigital'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:template match="metadata">
        <mhs:Sidecar xmlns:mhs="https://zeticon.mediahaven.com/metadata/22.1/mhs/"
            xmlns:mh="https://zeticon.mediahaven.com/metadata/22.1/mh/" version="22.1">
            <!-- Dynamic-->
            <xsl:element name="mhs:Dynamic">
                <!-- Real workflow name (DEV-2104) -->
                <xsl:element name="ingest_workflow">sipin</xsl:element>
                <!-- CP (NAME)) -->
                <xsl:element name="CP">
                    <xsl:value-of select="$cp_name" />
                </xsl:element>
                <!-- CP ID -->
                <xsl:element name="CP_id">
                    <xsl:value-of select="$cp_id" />
                </xsl:element>
                <!-- SP name -->
                <xsl:element name="sp_name">
                    <xsl:value-of select="$sp_name" />
                </xsl:element>
                <!-- PID -->
                <xsl:element name="PID">
                    <xsl:value-of select="$pid" />
                </xsl:element>
                <!-- md5 -->
                <xsl:element name="md5">
                    <xsl:value-of select="$md5" />
                </xsl:element>
                <!-- Licenses -->
                <xsl:element name="dc_rights_licenses">
                    <xsl:apply-templates select="dcterms:license" />
                </xsl:element>
                <!-- Relations -->
                <xsl:element name="dc_relations">
                    <xsl:element name="is_deel_van">
                        <xsl:value-of select="substring-before($pid, '_')" />
                    </xsl:element>
                </xsl:element>
                <!-- Batch ID -->
                <xsl:if test="$batch_id">
                    <xsl:element name="batch_id">
                        <xsl:value-of select="$batch_id" />
                    </xsl:element>
                </xsl:if>
            </xsl:element>
        </mhs:Sidecar>
    </xsl:template>
    <!-- Licenses -->
    <xsl:template match="dcterms:license">
        <xsl:element name="multiselect">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>