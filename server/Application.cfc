<cfcomponent output="false">

    <cfset this.name = "ThatOneFeed" />
    <cfset this.sessionManagement = false />
    <cfset this.applicationTimeout = createTimespan(5, 0, 0, 0) />

    <cfset request.cookieName = this.name />

    <cffunction name="onRequestStart" output="false">
        <cfset var i = "" />
        <cfscript>
            request.isProduction = false; //cgi.beb_deployment EQ "production" OR getPageContext().getServletContext().getInitParameter("beb_deployment") EQ "production";
            request.feedly = structKeyExists(cookie, request.cookieName) && isJson(cookie[request.cookieName]) ? deserializeJson(cookie[request.cookieName]) : {};
            if (request.isProduction || (hasRefreshToken() && hash(getRefreshToken()) == "1cf74fb65cd7c8c510083100710ccaf7")) {
                // heh
                request.api = {
                    root = "http://cloud.feedly.com",
                    clientId = "feedly",
                    clientSecret = "0XP4XQ07VVMDWBKUHTJM4WUQ",
                    redirectUri = "http://dev.feedly.com/feedly.html"
                };
            } else {
                request.api = {
                    root = "http://sandbox.feedly.com",
                    clientId = "sandbox272",
                    clientSecret = "Y7PP7DM6J5LYGY62E3I7FJGO",
                    redirectUri = "http://localhost"
                };
            }
        </cfscript>
        <cfloop collection="#this#" item="i">
            <cfif isCustomFunction(this[i])>
                <cfset request[i] = this[i] />
            </cfif>
        </cfloop>
    </cffunction>

    <cffunction name="hasAccessToken" output="false">
        <cfreturn structKeyExists(request.feedly, 'at') AND structKeyExists(request.feedly, 'ex') AND request.feedly.ex GT (now().getTime() + 20000) />
    </cffunction>

    <cffunction name="hasRefreshToken" output="false">
        <cfreturn structKeyExists(request.feedly, 'rt') />
    </cffunction>

    <cffunction name="getRefreshToken" output="false">
        <cfreturn request.feedly.rt />
    </cffunction>

    <cffunction name="getAccessToken" output="false">
        <cfif NOT request.hasAccessToken() AND request.hasRefreshToken()>
            <cfset var http = "" />
        	<cfhttp url="#request.api.root#/v3/auth/token"
        			method="post"
                    result="http">
        		<cfhttpparam type="formfield" name="refresh_token" value="#getRefreshToken()#" />
        		<cfhttpparam type="formfield" name="client_id" value="#request.api.clientId#" />
        		<cfhttpparam type="formfield" name="client_secret" value="#request.api.clientSecret#" />
        		<cfhttpparam type="formfield" name="grant_type" value="refresh_token" />
        	</cfhttp>
        	<cfif http.status_code NEQ 200>
                <cfheader statuscode="#http.status_code#" statustext="#listRest(http.statuscode, ' ')#" />
        		<cfdump var="#http#" abort="true" />
        	</cfif>
        	<cfset var fc = deserializeJson(http.fileContent) />
            <cfset updateCookie(request.feedly.rt, fc.access_token, fc.expires_in) />
        </cfif>
        <cfreturn request.feedly.at />
    </cffunction>

    <cffunction name="inflateAuthCode" output="false">
        <cfargument name="code" />
        <cfset var http = "" />
        <cfhttp url="#request.api.root#/v3/auth/token"
                method="post"
                result="http">
            <cfhttpparam type="formfield" name="code" value="#code#" />
            <cfhttpparam type="formfield" name="client_id" value="#request.api.clientId#" />
            <cfhttpparam type="formfield" name="client_secret" value="#request.api.clientSecret#" />
            <cfhttpparam type="formfield" name="redirect_uri" value="#request.api.redirectUri#" />
            <cfhttpparam type="formfield" name="grant_type" value="authorization_code" />
            <cfhttpparam type="formfield" name="state" value="" />
        </cfhttp>
        <cfif http.status_code NEQ 200>
            <cfheader statuscode="#http.status_code#" statustext="#listRest(http.statuscode, ' ')#" />
            <cfdump var="#http#" abort="true" />
        </cfif>
        <cfset var fc = deserializeJson(http.fileContent) />
        <cfset request.updateCookie(fc.refresh_token, fc.access_token, fc.expires_in) />
    </cffunction>

    <cffunction name="updateCookie" output="false">
        <cfargument name="rt" />
        <cfargument name="at" />
        <cfargument name="ex" />
        <cfset request.feedly = {
            rt = rt,
            at = at,
            ex = dateAdd('s', ex - 600, now()).getTime()
        } />
        <cfcookie name="#request.cookieName#" value="#serializeJson(request.feedly)#" expires="never" />
    </cffunction>

    <cffunction name="deleteCookie" output="false">
        <cfset request.feedly = {} />
        <cfcookie name="#request.cookieName#" value="{}" expires="now" />
    </cffunction>

    <cffunction name="render">
        <cfargument name="body" />
        <cfcontent type="application/json" reset="true"
        /><cfoutput>#isSimpleValue(body) ? body : serializeJSON(body)#</cfoutput><cfabort />
    </cffunction>

</cfcomponent>