<!---
GET
--->

<cfhttp url="#request.api.root#/v3/markers/counts" throwonerror="true">
	<cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
</cfhttp>
<cfset request.render(cfhttp.filecontent) />