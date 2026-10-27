with source as (
    select * from {{ ref('ship_method') }}
),

renamed as (
    select
        ship_method_id,
        name as ship_method_name,
        cast(ship_base as numeric(19, 4)) as ship_base_rate,
        cast(ship_rate as numeric(19, 4)) as ship_rate_per_pound,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
