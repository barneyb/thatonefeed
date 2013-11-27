<!---
PUT / DELETE
tagId: globalSavedTagId
entryId: id
--->
<cfif cgi.request_method EQ "PUT">
    <cfset data = deserializeJson(getHttpRequestData().content) />
    <cfhttp method="PUT" url="#request.api.root#/v3/tags/#urlEncodedFormat(data.tagId)#" throwonerror="true">
        <cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
        <cfhttpparam type="body" value="#serializeJson({
            'entryId' = data.entryId
        })#" />
    </cfhttp>
    <cfset request.render(cfhttp.filecontent) />
<cfelseif cgi.request_method EQ "DELETE">
    <cfset data = deserializeJson(getHttpRequestData().content) />
    <cfhttp method="DELETE" url="#request.api.root#/v3/tags/#urlEncodedFormat(data.tagId)#/#urlEncodedFormat(data.entryId)#" throwonerror="true">
    	<cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
    </cfhttp>
    <cfset request.render(cfhttp.filecontent) />
</cfif>