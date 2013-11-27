<!---
oauth flow controller

:8080/thatonefeed/server/auth.cfm

--->
<cfif structKeyExists(url, 'state')>
    <!--- a response --->
    <cfif structKeyExists(url, 'code')>
        <cfset request.inflateAuthCode(url.code) />
        <cfoutput>
            <script>window.opener.location.replace("##/view");window.close();</script>
            OAuth delegation succeeded.  :)
        </cfoutput>
    <cfelse>
        <cfoutput>
            <script>window.opener.location.replace("##/decline");window.close();</script>
            Yeah, if you don't authorize Feedly, we can't do anything.
        </cfoutput>
    </cfif>
<cfelse>
    <cflocation url="#request.api.root#/v3/auth/auth?response_type=code&client_id=#request.api.clientId#&redirect_uri=#request.api.redirectUri#&scope=https://cloud.feedly.com/subscriptions&state=" addtoken="false" />
</cfif>