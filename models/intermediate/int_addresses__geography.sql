-- Flattens address -> state/province -> country -> sales territory.

with addresses as (
    select * from {{ ref('stg_adventureworks__addresses') }}
),

state_provinces as (
    select * from {{ ref('stg_adventureworks__state_provinces') }}
),

countries as (
    select * from {{ ref('stg_adventureworks__country_regions') }}
),

territories as (
    select * from {{ ref('stg_adventureworks__sales_territories') }}
),

joined as (
    select
        addresses.address_id,
        addresses.address_line_1,
        addresses.address_line_2,
        addresses.city,
        addresses.postal_code,
        state_provinces.state_province_code,
        state_provinces.state_province_name,
        countries.country_region_code,
        countries.country_region_name,
        territories.territory_id,
        territories.territory_name,
        territories.territory_group

    from addresses
    inner join state_provinces
        on addresses.state_province_id = state_provinces.state_province_id
    inner join countries
        on state_provinces.country_region_code = countries.country_region_code
    inner join territories
        on state_provinces.territory_id = territories.territory_id
)

select * from joined
