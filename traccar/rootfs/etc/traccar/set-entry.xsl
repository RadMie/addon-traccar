<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="xml"
        encoding="UTF-8"
        indent="yes"
        doctype-system="http://java.sun.com/dtd/properties.dtd"/>

    <xsl:param name="key"/>
    <xsl:param name="value"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="properties">
        <xsl:copy>
            <xsl:apply-templates
                select="@*|node()[not(self::entry and @key = $key)]"/>
            <entry key="{$key}"><xsl:value-of select="$value"/></entry>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
