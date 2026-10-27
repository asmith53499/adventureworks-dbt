with products as (
    select * from {{ ref('stg_adventureworks__products') }}
),

subcategories as (
    select * from {{ ref('stg_adventureworks__product_subcategories') }}
),

categories as (
    select * from {{ ref('stg_adventureworks__product_categories') }}
),

models as (
    select * from {{ ref('stg_adventureworks__product_models') }}
),

final as (
    select
        products.product_id,
        products.product_number,
        products.product_name,
        models.product_model_name,
        -- components (is_finished_good = false) have no subcategory
        coalesce(subcategories.product_subcategory_name, 'Component') as product_subcategory_name,
        coalesce(categories.product_category_name, 'Component') as product_category_name,
        products.product_line,
        products.product_class,
        products.product_style,
        products.color,
        products.size,
        products.weight,
        products.weight_unit_measure_code,

        products.is_finished_good,
        products.is_manufactured_in_house,

        products.list_price,
        products.standard_cost,
        products.list_price - products.standard_cost as list_margin,

        products.sell_start_date,
        products.sell_end_date,
        products.sell_end_date is null as is_currently_sold

    from products
    left join subcategories
        on products.product_subcategory_id = subcategories.product_subcategory_id
    left join categories
        on subcategories.product_category_id = categories.product_category_id
    left join models
        on products.product_model_id = models.product_model_id
)

select * from final
