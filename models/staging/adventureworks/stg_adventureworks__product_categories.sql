with source as (
    select * from {{ ref('product_category') }}
),

renamed as (
    select
        product_category_id,
        name as product_category_name,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
