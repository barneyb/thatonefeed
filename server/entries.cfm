<!---
GET
streamId: streamId
continuation: continuation
--->

<cfhttp url="#request.api.root#/v3/streams/contents" throwonerror="true">
    <cfhttpparam type="url" name="streamId" value="#url.streamId#" />
    <cfhttpparam type="url" name="ranked" value="oldest" />
    <cfhttpparam type="url" name="unreadOnly" value="true" />
    <cfif structKeyExists(url, "continuation") AND len(trim(url.continuation)) GT 0>
        <cfhttpparam type="url" name="continuation" value="#url.continuation#" />
    </cfif>
	<cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
</cfhttp>
<cfset request.render(cfhttp.filecontent) />