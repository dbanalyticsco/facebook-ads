{% macro stitch_fb_ad_creatives() %}

    {{ adapter_macro('facebook_ads.stitch_fb_ad_creatives') }}

{% endmacro %}


{% macro default__stitch_fb_ad_creatives() %}

with base as (
    
    select * from {{ var('ad_creatives_table') }}
    
),

child_links as (
    
    select * from {{ ref('fb_ad_creatives__child_links') }}
    
),

links_joined as (
    
    select
    
        id,
        lower(nullif(url_tags, '')) as url_tags,
        lower(coalesce(
          nullif(child_link, ''),
          nullif(object_story_spec__link_data__call_to_action__value__link, ''),
          nullif(object_story_spec__video_data__call_to_action__value__link, ''),
          nullif(object_story_spec__link_data__link, '')
        )) as url
    
    from base
    left join child_links using (id)
    
), 

splits as (

    select
    
        links_joined.*,
        {{ dbt_utils.split_part('url', "'?'", 1) }} as base_url,
        --this is a strange thing to have to do but it's because sometimes 
        --the URL exists on the story object and we wouldn't get the appropriate 
        --UTM params here otherwise
        coalesce(url_tags, {{ dbt_utils.split_part('url', "'?'", 2) }} ) as url_tags
    
    from links_joined

)

select

    splits.*,
    {{ dbt_utils.get_url_host('url') }} as url_host,
    '/' || {{dbt_utils.get_url_path('url') }} as url_path,
    {{ dbt_utils.get_url_parameter('url', 'utm_source') }} as utm_source,
    {{ dbt_utils.get_url_parameter('url', 'utm_medium') }} as utm_medium,
    {{ dbt_utils.get_url_parameter('url', 'utm_campaign') }} as utm_campaign,
    {{ dbt_utils.get_url_parameter('url', 'utm_content') }} as utm_content,
    {{ dbt_utils.get_url_parameter('url', 'utm_term') }} as utm_term
    
from splits

{% endmacro %}


{% macro snowflake__stitch_fb_ad_creatives() %}

with base as (
    
    select * from {{ var('ad_creatives_table') }}
    
),

child_links as (
    
    select * from {{ ref('fb_ad_creatives__child_links') }}
    
),

links_joined as (
    
    select
    
        id,
        lower(coalesce(
            nullif(child_link, ''),
            nullif(object_story_spec['link_data']['call_to_action']['value']['link']::varchar, ''),
            nullif(object_story_spec['video_data']['call_to_action']['value']['link']::varchar, ''),
            nullif(object_story_spec['link_data']['link']::varchar, '')
        )) as url
        
    from base
    left join child_links using (id)

),

parsed as (

    select
    
        links_joined.*,
        {{ dbt_utils.split_part('url', "'?'", 1) }} as base_url,
        {{ dbt_utils.get_url_host('url') }} as url_host,
        '/' || {{ dbt_utils.get_url_path('url') }} as url_path,
        {{ dbt_utils.get_url_parameter('url', 'utm_source') }} as utm_source,
        {{ dbt_utils.get_url_parameter('url', 'utm_medium') }} as utm_medium,
        {{ dbt_utils.get_url_parameter('url', 'utm_campaign') }} as utm_campaign,
        {{ dbt_utils.get_url_parameter('url', 'utm_content') }} as utm_content,
        {{ dbt_utils.get_url_parameter('url', 'utm_term') }} as utm_term
        
    from links_joined 

)

select * from parsed

{% endmacro %}