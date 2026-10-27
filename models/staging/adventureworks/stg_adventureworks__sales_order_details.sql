with source as (
    select * from {{ ref('sales_order_detail') }}
),

renamed as (
    select
        -- ids
        sales_order_detail_id,
        sales_order_id,
        product_id,
        special_offer_id,

        -- strings
        carrier_tracking_number,

        -- numerics
        order_qty as order_quantity,
        cast(unit_price as numeric(19, 4)) as unit_price,
        -- stored as a fraction, e.g. 0.10 = 10% off
        cast(unit_price_discount as numeric(19, 4)) as unit_price_discount_pct,
        -- line_total = unit_price * (1 - discount) * qty, computed in the source
        cast(line_total as numeric(38, 6)) as line_total,

        -- timestamps
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
