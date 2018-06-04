{% set partition_clause = "partition by id order by effective_status rows
    between unbounded preceding and unbounded following" %}

with fb_adsets as (

    select  * from {{ref('FB_ADS_ADSETS')}}

),

rollup as (

    select distinct
        id,
        first_value(name) over ({{partition_clause}}) as name,
        first_value(account_id) over ({{partition_clause}}) as account_id,
        first_value(campaign_id) over ({{partition_clause}}) as campaign_id,
        first_value(created_time) over ({{partition_clause}}) as created_time,
        first_value(effective_status) over ({{partition_clause}})
            as effective_status
    from fb_adsets

)

select * from rollup