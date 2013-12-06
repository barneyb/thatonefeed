<!---
GET - retrieve preferences from feedly
POST - send new preferences to feedly
--->

<cfif cgi.request_method EQ "GET">
    <cfhttp method="GET" url="#request.api.root#/v3/preferences" throwonerror="true">
    	<cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
    </cfhttp>
    <cfset request.render(cfhttp.filecontent) />
<cfelseif cgi.request_method EQ "POST">
    <cfhttp method="POST" url="#request.api.root#/v3/preferences" throwonerror="true">
        <cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
        <cfhttpparam type="body" value="#getHttpRequestData().content#" />
    </cfhttp>
    <cfset request.render(cfhttp.filecontent) />
</cfif>
