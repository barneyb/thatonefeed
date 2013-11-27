<!---
GET
--->

<cfhttp url="#request.api.root#/v3/categories" throwonerror="true">
	<cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
</cfhttp>
<cfset request.render(cfhttp.filecontent) />