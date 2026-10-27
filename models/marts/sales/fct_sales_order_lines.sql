-- Grain: one row per sales order line. Order-level keys are denormalized from
-- the header so the table can be sliced without joining fct_sales_orders.

with lines as (
    select * from {{ ref('int_sales_order_lines__costed') }}
),

orders as (
    select * from {{ ref('stg_adventureworks__sales_order_headers') }}
),

final as (
    select
        -- keys
        lines.sales_order_detail_id,
        lines.sales_order_id,
        orders.sales_order_number,
        lines.order_date,
        orders.customer_id,
        lines.product_id,
        lines.special_offer_id,
        orders.sales_person_id,
        orders.territory_id,
        orders.ship_to_address_id,

        orders.is_online_order,

        -- measures
        lines.order_quantity,
        lines.unit_price,
        lines.unit_price_discount_pct,
        lines.unit_price * lines.order_quantity as gross_sales_amount,
        lines.unit_price * lines.order_quantity - lines.line_total as discount_amount,
        lines.line_total as net_sales_amount,

        lines.unit_cost,
        lines.unit_cost * lines.order_quantity as cost_amount,
        lines.line_total - lines.unit_cost * lines.order_quantity as gross_margin_amount,
        lines.is_cost_estimated

    from lines
    inner join orders
        on lines.sales_order_id = orders.sales_order_id
)

select * from final
