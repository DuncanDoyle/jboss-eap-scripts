<?xml version="1.0" encoding="UTF-8"?>

<!--
	Parses the input file (a JBoss module.xml template file) and adds all the resources provided in the 'resources.xml' file.

	author: ddoyle@redhat.com
-->
<xsl:stylesheet xmlns="urn:jboss:module:1.1" xmlns:jbm="urn:jboss:module:1.1" xmlns:res="urn:jboss:ddoyle:resources:1.0" xmlns:dep="urn:jboss:ddoyle:dependencies:1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:str="http://exslt.org/strings" extension-element-prefixes="str" exclude-result-prefixes="jbm" version="1.0">

   
   <xsl:param name="moduleName" select="'default.name'"/>

   <xsl:output method="xml" indent="yes" />

   <!-- load the resources (filenames) from the resources.xml file. -->
   <xsl:variable name="resources" select="document('resources.xml')"/>
   <xsl:variable name="dependencies" select="document('dependencies.xml')"/>

   <xsl:template match="/jbm:module">
	<xsl:copy>
		<xsl:attribute name="name">
			<xsl:value-of select="$moduleName"/>
		</xsl:attribute>
		<xsl:apply-templates />		
	</xsl:copy>
   </xsl:template>

   <!-- match on the '<resources>' tag in the template file and all the resources from the 'resources.xml'. -->
   <xsl:template match="jbm:resources">
      <xsl:copy>
         <xsl:for-each select="$resources/res:resources/res:resource">
	   <resource-root>
	      <xsl:attribute name="path">
	         <xsl:value-of select="."/>
	      </xsl:attribute>
           </resource-root>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="jbm:dependencies">
      <xsl:copy>
         <xsl:for-each select="$dependencies/dep:dependencies/dep:module">
	   <module>
	      <xsl:attribute name="name">
	         <xsl:value-of select="@name"/>
	      </xsl:attribute>
           </module>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>




   <!-- Copy everything that doesn't match. -->
   <xsl:template match="@*|node()">
      <xsl:copy>
         <xsl:apply-templates select="@*|node()" />
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
