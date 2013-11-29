<!---
GET
--->

<cfhttp url="#request.api.root#/v3/markers/counts" throwonerror="true">
	<cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
    <cfif structKeyExists(url, 'background') AND isBoolean(url.background) AND url.background>
        <cfhttpparam type="url" name="autorefresh" value="true" />
    </cfif>
</cfhttp>
<cfset request.render(cfhttp.filecontent) />