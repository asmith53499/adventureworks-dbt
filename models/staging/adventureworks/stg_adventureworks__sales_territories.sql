with source as (
    select * from {{ ref('sales_territory') }}
),

renamed as (
    select
        territory_id,
        name as territory_name,
        country_region_code,
        territory_group,
        cast(modified_date as timestamp) as modified_at

        -- sales_ytd / cost_ytd are snapshot rollups maintained by the OLTP app;
        -- they're dropped in favour of deriving sales from the order tables.

    from source
)

select * from renamed
