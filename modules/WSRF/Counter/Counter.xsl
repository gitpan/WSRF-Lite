<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method='html' version='1.0' encoding='UTF-8' indent='yes' />

	<xsl:template match="/" xmlns:mmk="http://www.sve.man.ac.uk/Counter"
		xmlns:wsrp="http://docs.oasis-open.org/wsrf/rp-2"
		xmlns:wsrl="http://docs.oasis-open.org/wsrf/rl-2">
		<html>
			<head>
				<link rel="stylesheet" href="Counter.css" type="text/css" />
				<script type="text/javascript" src="Counter.js" />
			</head>
			<body onLoad="javascript: return onLoad();">
				<h2>Counter ResourceProperties</h2>
				<form name="prop">
					<table border="1">
						<tr>
							<th align="left">Property</th>
							<th align="left">Value</th>
						</tr>
						<tr>
							<td class="modifiable">count</td>
							<td class="modifiable">
								<input id="count" type="text" size="20">
									<xsl:attribute name="value">
										<xsl:value-of select="/wsrp:ResourceProperties/mmk:count" />
									</xsl:attribute>
									<xsl:attribute name="onkeypress">javascript: if ((event.which &amp;&amp; event.which == 13) || (event.keyCode &amp;&amp; event.keyCode == 13)) { return updateResourcePropertiesFromPage(); }</xsl:attribute>
								</input>
							</td>
						</tr>
						<tr>
							<td class="modifiable">wsrl:TerminationTime</td>
							<td class="modifiable">
								<input id="TerminationTime" type="text" size="20" >
									<xsl:attribute name="value">
										<xsl:value-of select="/wsrp:ResourceProperties/wsrl:TerminationTime" />
									</xsl:attribute>
									<xsl:attribute name="onkeypress">javascript: if ((event.which &amp;&amp; event.which == 13) || (event.keyCode &amp;&amp; event.keyCode == 13)) { return updateResourcePropertiesFromPage(); }</xsl:attribute>
								</input>
							</td>
						</tr>
						<tr>
							<td>wsrl:CurrentTime</td>
							<td id="CurrentTime">
								<xsl:value-of select="/wsrp:ResourceProperties/wsrl:CurrentTime" />
							</td>
						</tr>
						<tr>
							<td>LocalTime</td>
							<td id="localtime"></td>
						</tr>
						<tr>
							<td>UpdateRate (sec)</td>
							<td id="updateRate">10</td>
						</tr>
						<tr>
							<td colspan="2" align="center" id="submitUpdates" class="idle">
								<input type="button" value="Update Values" onclick="javascript: return updateResourcePropertiesFromPage();" />
							</td>
						</tr>
					</table>
				</form>
				<table>
					<br />
					<tr>
						<td>
							<form name="stop">
								<input type="button" value="Stop Polling" onclick="javascript: return stopUpdating();" />
							</form>
						</td>
						<td>
							<form name="restart">
								<input type="button" value="Resume Polling" onclick="javascript: return resumeUpdating();" />
							</form>
						</td>
						<td>
							<form name="faster">
								<input type="button" value="Poll Faster" onclick="javascript: return increaseUpdateRate();" />
							</form>
						</td>
						<td>
							<form name="slower">
								<input type="button" value="Poll Slower" onclick="javascript: return decreaseUpdateRate();"/>
							</form>
						</td>
					</tr>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>

