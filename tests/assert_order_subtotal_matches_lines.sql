-- The order header subtotal should equal the sum of its line net amounts.
-- Any row returned is a failure.

select
    orders.sales_order_id,
    orders.subtotal,
    sum(lines.net_sales_amount) as sum_of_lines

from {{ ref('fct_sales_orders') }} as orders
inner join {{ ref('fct_sales_order_lines') }} as lines
    on orders.sales_order_id = lines.sales_order_id
group by 1, 2
having abs(orders.subtotal - sum(lines.net_sales_amount)) > 0.01
