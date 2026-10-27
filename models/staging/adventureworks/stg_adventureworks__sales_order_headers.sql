with source as (
    select * from {{ ref('sales_order_header') }}
),

renamed as (
    select
        -- ids
        sales_order_id,
        customer_id,
        sales_person_id,
        territory_id,
        bill_to_address_id,
        ship_to_address_id,
        ship_method_id,
        currency_rate_id,

        -- strings
        sales_order_number,
        purchase_order_number,
        account_number,
        cast(comment as varchar) as order_comment,
        status as status_code,
        case status
            when 1 then 'In Process'
            when 2 then 'Approved'
            when 3 then 'Backordered'
            when 4 then 'Rejected'
            when 5 then 'Shipped'
            when 6 then 'Cancelled'
        end as status,

        -- booleans
        -- online orders are placed by individuals; offline orders come through a salesperson
        cast(online_order_flag as boolean) as is_online_order,

        -- numerics
        revision_number,
        cast(sub_total as numeric(19, 4)) as subtotal,
        cast(tax_amt as numeric(19, 4)) as tax_amount,
        cast(freight as numeric(19, 4)) as freight,
        cast(total_due as numeric(19, 4)) as total_due,

        -- dates (source stores dates as datetimes with a zero time part)
        cast(cast(order_date as timestamp) as date) as order_date,
        cast(cast(due_date as timestamp) as date) as due_date,
        cast(cast(ship_date as timestamp) as date) as ship_date,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
