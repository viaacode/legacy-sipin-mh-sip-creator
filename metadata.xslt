<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:premis="http://www.loc.gov/premis/v3" xmlns:mhs="https://zeticon.mediahaven.com/metadata/22.1/mhs/" xmlns:mh="https://zeticon.mediahaven.com/metadata/22.1/mh/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="dc premis dcterms xsi" version="1.1">
    <xsl:output version="1.0" encoding="UTF-8" standalone="yes" indent="yes" />
    <xsl:template match="premis:object">
        <mhs:Sidecar xmlns:mhs="https://zeticon.mediahaven.com/metadata/22.1/mhs/" xmlns:mh="https://zeticon.mediahaven.com/metadata/22.1/mh/" version="22.1">
            <!-- Descriptive -->
            <xsl:element name="mhs:Descriptive">
                <xsl:apply-templates select="dcterms:title[not(@xsi:type)]" />
            </xsl:element>
            <!-- Dynamic-->
            <xsl:element name="mhs:Dynamic">
                <xsl:apply-templates select="dcterms:identifier" />
            </xsl:element>
        </mhs:Sidecar>
    </xsl:template>
    <!-- Descriptive -->
    <!-- Title -->
    <xsl:template match="dcterms:title">
        <xsl:element name="mh:Title">
            <xsl:value-of select=" text()" />
        </xsl:element>
    </xsl:template>
    <!-- Dynamic-->
    <!-- PID -->
    <xsl:template match="dcterms:identifier">
        <xsl:element name="PID">
            <xsl:value-of select=" text()" />
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>