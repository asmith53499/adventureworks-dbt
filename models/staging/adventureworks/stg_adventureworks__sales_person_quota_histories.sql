with source as (
    select * from {{ ref('sales_person_quota_history') }}
),

renamed as (
    select
        business_entity_id as sales_person_id,
        cast(cast(quota_date as timestamp) as date) as quota_date,
        cast(sales_quota as numeric(19, 4)) as sales_quota,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
