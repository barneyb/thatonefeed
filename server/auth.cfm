<!---
oauth flow controller
--->
<cfif structKeyExists(url, 'code')>
    <cfset request.inflateAuthCode(url.code) />
<cfelse>
    <cflocation url="#request.api.root#/v3/auth/auth?response_type=code&client_id=#request.api.clientId#&redirect_uri=#request.api.redirectUri#&scope=https://cloud.feedly.com/subscriptions&state=" addtoken="false" />
</cfif>