with source as (
    select * from {{ ref('sales_reason') }}
),

renamed as (
    select
        sales_reason_id,
        name as sales_reason_name,
        reason_type as sales_reason_type,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
