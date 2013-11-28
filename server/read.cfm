<!---
POST
id: id
    OR
ids: ids
--->
<cfset body = deserializeJson(getHttpRequestData().content) />
<cfset ids = structKeyExists(body, 'ids') ? body.ids : [body.id] />
<cfabort />
<cfhttp method="POST" url="#request.api.root#/v3/markers" throwonerror="true">
	<cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
    <cfhttpparam type="body" value="#serializeJson({
        'action' = 'markAsRead',
        'type' = 'entries',
        'entryIds' = ids
    })#" />
</cfhttp>
<cfset request.render(cfhttp.filecontent) />