-- Attaches the standard cost in effect on the order date to each order line, so
-- margin reflects historical cost rather than today's product.standard_cost.

with order_lines as (
    select * from {{ ref('stg_adventureworks__sales_order_details') }}
),

orders as (
    select * from {{ ref('stg_adventureworks__sales_order_headers') }}
),

cost_history as (
    select * from {{ ref('stg_adventureworks__product_cost_histories') }}
),

products as (
    select * from {{ ref('stg_adventureworks__products') }}
),

joined as (
    select
        order_lines.sales_order_detail_id,
        order_lines.sales_order_id,
        order_lines.product_id,
        order_lines.special_offer_id,
        orders.order_date,
        order_lines.order_quantity,
        order_lines.unit_price,
        order_lines.unit_price_discount_pct,
        order_lines.line_total,

        -- a handful of lines predate their product's first cost record; fall back
        -- to the current standard cost and flag them
        coalesce(cost_history.standard_cost, products.standard_cost) as unit_cost,
        cost_history.product_id is null as is_cost_estimated

    from order_lines
    inner join orders
        on order_lines.sales_order_id = orders.sales_order_id
    inner join products
        on order_lines.product_id = products.product_id
    left join cost_history
        on order_lines.product_id = cost_history.product_id
        and orders.order_date >= cost_history.valid_from
        and (orders.order_date <= cost_history.valid_to or cost_history.valid_to is null)
)

select * from joined
