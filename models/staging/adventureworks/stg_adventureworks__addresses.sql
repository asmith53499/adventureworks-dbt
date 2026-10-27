with source as (
    select * from {{ ref('address') }}
),

renamed as (
    select
        address_id,
        state_province_id,
        address_line1 as address_line_1,
        address_line2 as address_line_2,
        city,
        postal_code,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
