<cfhttp url="#request.api.root#/v3/profile" throwonerror="true">
    <cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
</cfhttp>
<cfhttp url="#url.url#" throwonerror="true" />
<cfset request.render({"url": url.url, "body": cfhttp.filecontent}) />