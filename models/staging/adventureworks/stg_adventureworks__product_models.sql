with source as (
    select * from {{ ref('product_model') }}
),

renamed as (
    select
        product_model_id,
        name as product_model_name,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
