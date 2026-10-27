with source as (
    select * from {{ ref('product') }}
),

renamed as (
    select
        -- ids
        product_id,
        product_subcategory_id,
        product_model_id,

        -- strings
        name as product_name,
        product_number,
        color,
        size,
        size_unit_measure_code,
        weight_unit_measure_code,

        -- single-letter codes are nchar(2) in the source, so they carry a trailing space
        case trim(product_line)
            when 'R' then 'Road'
            when 'M' then 'Mountain'
            when 'T' then 'Touring'
            when 'S' then 'Standard'
        end as product_line,
        case trim(class)
            when 'H' then 'High'
            when 'M' then 'Medium'
            when 'L' then 'Low'
        end as product_class,
        case trim(style)
            when 'W' then 'Womens'
            when 'M' then 'Mens'
            when 'U' then 'Universal'
        end as product_style,

        -- booleans
        cast(make_flag as boolean) as is_manufactured_in_house,
        -- false = component used to build other products, not sold on its own
        cast(finished_goods_flag as boolean) as is_finished_good,

        -- numerics
        cast(standard_cost as numeric(19, 4)) as standard_cost,
        cast(list_price as numeric(19, 4)) as list_price,
        cast(weight as numeric(10, 2)) as weight,
        safety_stock_level,
        reorder_point,
        days_to_manufacture,

        -- dates
        cast(cast(sell_start_date as timestamp) as date) as sell_start_date,
        cast(cast(sell_end_date as timestamp) as date) as sell_end_date,
        cast(cast(discontinued_date as timestamp) as date) as discontinued_date,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
