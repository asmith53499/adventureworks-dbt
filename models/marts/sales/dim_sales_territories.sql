with territories as (
    select * from {{ ref('stg_adventureworks__sales_territories') }}
),

countries as (
    select * from {{ ref('stg_adventureworks__country_regions') }}
),

final as (
    select
        territories.territory_id,
        territories.territory_name,
        territories.territory_group,
        territories.country_region_code,
        countries.country_region_name

    from territories
    inner join countries
        on territories.country_region_code = countries.country_region_code
)

select * from final
