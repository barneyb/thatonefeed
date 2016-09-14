<!---
PUT
tagId: globalSavedTagId
entryId: id
published: unix_timestamp
type: 'image' | 'html'
title: 'string'
link: 'url'
content: 'html string'
( image: 'url' )?
--->
<!---
create table item (
    id bigint not null auto_increment,
    ts datetime not null,
    entry_id varchar(100),
    entry_ts datetime,
    type enum('image', 'html'),
    title varchar(255),
    link varchar(255),
    content mediumtext,
    image_url varchar(200) not null,
    constraint pk_item primary key (id),
    constraint uk_entry_image unique key (entry_id, image_url)
);
alter table item
    add processed_ts datetime;
--->
<cfset data = deserializeJson(getHttpRequestData().content) />
<cfhttp method="PUT" url="#request.api.root#/v3/tags/#urlEncodedFormat(data.tagId)#" throwonerror="true">
    <cfhttpparam type="header" name="Authorization" value="OAuth #request.getAccessToken()#" />
    <cfhttpparam type="body" value="#serializeJson({
        'entryId' = data.entryId
    })#" />
</cfhttp>
<cfif data.type NEQ 'image'>
    <cfset data.image = '' />
</cfif>
<cfquery>
    insert into item
        (ts, entry_id, entry_ts,
         type, title, link,
         content, image_url
        )
    values
        (now(),
         <cfqueryparam cfsqltype="cf_sql_varchar" value="#data.entryId#" />,
         from_unixtime(<cfqueryparam cfsqltype="cf_sql_bigint" value="#data.published#" /> / 1000), <!--- it's passed as millis --->
         <cfqueryparam cfsqltype="cf_sql_varchar" value="#data.type#" />,
         <cfqueryparam cfsqltype="cf_sql_varchar" value="#data.title#" />,
         <cfqueryparam cfsqltype="cf_sql_varchar" value="#data.link#" />,
         <cfqueryparam cfsqltype="cf_sql_varchar" value="#data.content#" />,
         <cfqueryparam cfsqltype="cf_sql_varchar" value="#data.image#" />
        )
    on duplicate key update
        entry_ts = values(entry_ts),
        title = values(title),
        link = values(link),
        content = values(content)
</cfquery>
<cfoutput>#serializeJSON(data)#</cfoutput>
