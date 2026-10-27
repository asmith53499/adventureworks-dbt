with source as (
    select * from {{ ref('sales_person') }}
),

renamed as (
    select
        -- business_entity_id is shared with person and employee
        business_entity_id as sales_person_id,
        territory_id,
        cast(sales_quota as numeric(19, 4)) as current_sales_quota,
        cast(bonus as numeric(19, 4)) as bonus,
        cast(commission_pct as numeric(10, 4)) as commission_pct,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
