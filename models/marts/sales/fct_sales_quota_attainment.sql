-- Grain: one row per salesperson per quota period.
--
-- Quotas are set roughly quarterly but on irregular dates, so each period runs
-- from its quota_date up to (not including) the salesperson's next quota_date.
-- The final period is assumed to last three months.

with quotas as (
    select * from {{ ref('stg_adventureworks__sales_person_quota_histories') }}
),

orders as (
    select * from {{ ref('stg_adventureworks__sales_order_headers') }}
),

quota_periods as (
    select
        sales_person_id,
        quota_date as period_start_date,
        coalesce(
            lead(quota_date) over (partition by sales_person_id order by quota_date),
            cast({{ dbt.dateadd('month', 3, 'quota_date') }} as date)
        ) as period_end_date,
        sales_quota

    from quotas
),

period_sales as (
    select
        quota_periods.sales_person_id,
        quota_periods.period_start_date,
        count(orders.sales_order_id) as order_count,
        coalesce(sum(orders.subtotal), 0) as sales_amount

    from quota_periods
    left join orders
        on quota_periods.sales_person_id = orders.sales_person_id
        and orders.order_date >= quota_periods.period_start_date
        and orders.order_date < quota_periods.period_end_date
    group by 1, 2
),

final as (
    select
        quota_periods.sales_person_id,
        quota_periods.period_start_date,
        quota_periods.period_end_date,
        quota_periods.sales_quota,
        period_sales.order_count,
        period_sales.sales_amount,
        period_sales.sales_amount - quota_periods.sales_quota as variance_to_quota,
        case
            when quota_periods.sales_quota > 0
                then period_sales.sales_amount / quota_periods.sales_quota
        end as quota_attainment_pct,
        period_sales.sales_amount >= quota_periods.sales_quota as is_quota_met

    from quota_periods
    inner join period_sales
        on quota_periods.sales_person_id = period_sales.sales_person_id
        and quota_periods.period_start_date = period_sales.period_start_date
)

select * from final
