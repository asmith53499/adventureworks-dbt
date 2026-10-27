-- Grain: one row per sales order. Amounts are in USD; currency_code and
-- total_due_local_currency show what the customer was billed in.

with orders as (
    select * from {{ ref('stg_adventureworks__sales_order_headers') }}
),

lines as (
    select * from {{ ref('fct_sales_order_lines') }}
),

order_reasons as (
    select * from {{ ref('stg_adventureworks__sales_order_header_sales_reasons') }}
),

reasons as (
    select * from {{ ref('stg_adventureworks__sales_reasons') }}
),

ship_methods as (
    select * from {{ ref('stg_adventureworks__ship_methods') }}
),

currency_rates as (
    select * from {{ ref('stg_adventureworks__currency_rates') }}
),

line_totals as (
    select
        sales_order_id,
        count(*) as line_count,
        sum(order_quantity) as total_quantity,
        sum(gross_sales_amount) as gross_sales_amount,
        sum(discount_amount) as discount_amount,
        sum(cost_amount) as cost_amount,
        sum(gross_margin_amount) as gross_margin_amount

    from lines
    group by 1
),

-- an order can cite several purchase reasons; collapse them to one string
reason_lists as (
    select
        order_reasons.sales_order_id,
        count(*) as sales_reason_count,
        {{ dbt.listagg('reasons.sales_reason_name', "', '", 'order by reasons.sales_reason_name') }} as sales_reasons

    from order_reasons
    inner join reasons
        on order_reasons.sales_reason_id = reasons.sales_reason_id
    group by 1
),

final as (
    select
        -- keys
        orders.sales_order_id,
        orders.sales_order_number,
        orders.purchase_order_number,
        orders.customer_id,
        orders.sales_person_id,
        orders.territory_id,
        orders.bill_to_address_id,
        orders.ship_to_address_id,

        -- dates
        orders.order_date,
        orders.due_date,
        orders.ship_date,
        {{ dbt.datediff('orders.order_date', 'orders.ship_date', 'day') }} as days_to_ship,
        orders.ship_date > orders.due_date as is_shipped_late,

        -- attributes
        orders.status,
        orders.is_online_order,
        ship_methods.ship_method_name,
        coalesce(currency_rates.to_currency_code, 'USD') as currency_code,
        reason_lists.sales_reasons,
        coalesce(reason_lists.sales_reason_count, 0) as sales_reason_count,

        -- measures (USD)
        line_totals.line_count,
        line_totals.total_quantity,
        line_totals.gross_sales_amount,
        line_totals.discount_amount,
        orders.subtotal,
        orders.tax_amount,
        orders.freight,
        orders.total_due,
        line_totals.cost_amount,
        line_totals.gross_margin_amount,
        orders.total_due * coalesce(currency_rates.average_rate, 1) as total_due_local_currency

    from orders
    inner join line_totals
        on orders.sales_order_id = line_totals.sales_order_id
    inner join ship_methods
        on orders.ship_method_id = ship_methods.ship_method_id
    left join currency_rates
        on orders.currency_rate_id = currency_rates.currency_rate_id
    left join reason_lists
        on orders.sales_order_id = reason_lists.sales_order_id
)

select * from final
