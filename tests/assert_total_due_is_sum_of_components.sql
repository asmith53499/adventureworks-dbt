-- total_due is a computed column in the source; guard against it drifting from
-- its definition if the data is ever regenerated.

select
    sales_order_id,
    subtotal,
    tax_amount,
    freight,
    total_due

from {{ ref('fct_sales_orders') }}
where abs(total_due - (subtotal + tax_amount + freight)) > 0.0001
