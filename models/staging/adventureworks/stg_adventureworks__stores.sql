with source as (
    select * from {{ ref('store') }}
),

renamed as (
    select
        business_entity_id as store_id,
        name as store_name,
        sales_person_id,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
