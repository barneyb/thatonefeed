<!---
GET - retrieve the profile from feedly, and augment w/ apiRoot
DELETE - log out/delete cookie, nothing to feedly
--->

<cfif cgi.request_method EQ "GET">
    <cfif request.hasAccessToken()>
        <cfhttp url="#request.api.root#/v3/profile" throwonerror="true">
            <cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
        </cfhttp>
        <cfset json = deserializeJSON(cfhttp.filecontent) />
        <cfset json['apiRoot'] = request.api.root />
        <cfset request.render(json) />
    <cfelse>
        <cfheader statuscode="401" statustext="Unauthorized. Muahhhahahahhahahha." />
        <cfcontent type="application/json" reset="true"
        /><cfabort />
    </cfif>
<cfelseif cgi.request_method EQ "DELETE">
    <cfset request.deleteCookie() />
</cfif>