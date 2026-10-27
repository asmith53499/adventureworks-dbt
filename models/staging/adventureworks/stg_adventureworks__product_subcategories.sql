with source as (
    select * from {{ ref('product_subcategory') }}
),

renamed as (
    select
        product_subcategory_id,
        product_category_id,
        name as product_subcategory_name,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
