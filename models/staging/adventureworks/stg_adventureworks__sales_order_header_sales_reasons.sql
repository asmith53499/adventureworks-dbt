with source as (
    select * from {{ ref('sales_order_header_sales_reason') }}
),

renamed as (
    select
        sales_order_id,
        sales_reason_id,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
