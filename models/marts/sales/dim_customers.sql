-- One row per customer. AdventureWorks sells to two kinds of customer:
--   * individuals buying online (customer.person_id set, store_id null)
--   * reseller stores buying through a salesperson (store_id set; person_id,
--     when present, is the store's purchasing contact)

with customers as (
    select * from {{ ref('stg_adventureworks__customers') }}
),

persons as (
    select * from {{ ref('stg_adventureworks__persons') }}
),

stores as (
    select * from {{ ref('stg_adventureworks__stores') }}
),

territories as (
    select * from {{ ref('stg_adventureworks__sales_territories') }}
),

orders as (
    select * from {{ ref('stg_adventureworks__sales_order_headers') }}
),

customer_orders as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(*) as lifetime_orders,
        sum(subtotal) as lifetime_sales_amount

    from orders
    group by 1
),

final as (
    select
        customers.customer_id,
        customers.account_number,

        case when customers.store_id is not null then 'Store' else 'Individual' end as customer_type,
        coalesce(stores.store_name, persons.full_name) as customer_name,
        stores.store_name,
        persons.full_name as contact_name,
        stores.sales_person_id as store_sales_person_id,

        customers.territory_id,
        territories.territory_name,
        territories.country_region_code,
        territories.territory_group,

        customer_orders.first_order_date,
        customer_orders.most_recent_order_date,
        coalesce(customer_orders.lifetime_orders, 0) as lifetime_orders,
        coalesce(customer_orders.lifetime_sales_amount, 0) as lifetime_sales_amount,
        customer_orders.customer_id is not null as has_ordered

    from customers
    left join persons
        on customers.person_id = persons.person_id
    left join stores
        on customers.store_id = stores.store_id
    left join territories
        on customers.territory_id = territories.territory_id
    left join customer_orders
        on customers.customer_id = customer_orders.customer_id
)

select * from final
