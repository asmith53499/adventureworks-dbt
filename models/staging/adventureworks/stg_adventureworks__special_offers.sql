with source as (
    select * from {{ ref('special_offer') }}
),

renamed as (
    select
        special_offer_id,
        description as special_offer_description,
        type as special_offer_type,
        category as special_offer_category,
        cast(discount_pct as numeric(10, 4)) as discount_pct,
        min_qty as min_quantity,
        max_qty as max_quantity,
        cast(cast(start_date as timestamp) as date) as start_date,
        cast(cast(end_date as timestamp) as date) as end_date,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
