with source as (
    select * from {{ ref('product_cost_history') }}
),

renamed as (
    select
        product_id,
        cast(cast(start_date as timestamp) as date) as valid_from,
        -- null end_date = the current cost
        cast(cast(end_date as timestamp) as date) as valid_to,
        cast(standard_cost as numeric(19, 4)) as standard_cost,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
