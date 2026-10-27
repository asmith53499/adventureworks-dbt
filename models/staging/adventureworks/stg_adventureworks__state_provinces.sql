with source as (
    select * from {{ ref('state_province') }}
),

renamed as (
    select
        state_province_id,
        territory_id,
        trim(state_province_code) as state_province_code,
        name as state_province_name,
        country_region_code,
        -- true when the country has no subdivisions and the row stands in for the whole country
        cast(is_only_state_province_flag as boolean) as is_country_only,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
