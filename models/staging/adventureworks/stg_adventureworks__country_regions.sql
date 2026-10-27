with source as (
    select * from {{ ref('country_region') }}
),

renamed as (
    select
        country_region_code,
        name as country_region_name,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
