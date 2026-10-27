-- Calendar spanning the order history. AdventureWorks' fiscal year runs
-- July-June and is named for the calendar year it ends in (FY2023 = Jul 2022 - Jun 2023).

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('calendar_start_date') ~ "' as date)",
        end_date="cast('" ~ var('calendar_end_date') ~ "' as date)"
    ) }}
),

days as (
    select cast(date_day as date) as date_day from date_spine
),

enriched as (
    select
        date_day,

        extract(year from date_day) as calendar_year,
        extract(quarter from date_day) as calendar_quarter,
        extract(month from date_day) as month_of_year,
        extract(day from date_day) as day_of_month,
        {{ day_of_week_iso('date_day') }} as day_of_week,

        case extract(month from date_day)
            when 1 then 'January'
            when 2 then 'February'
            when 3 then 'March'
            when 4 then 'April'
            when 5 then 'May'
            when 6 then 'June'
            when 7 then 'July'
            when 8 then 'August'
            when 9 then 'September'
            when 10 then 'October'
            when 11 then 'November'
            when 12 then 'December'
        end as month_name,

        case {{ day_of_week_iso('date_day') }}
            when 1 then 'Monday'
            when 2 then 'Tuesday'
            when 3 then 'Wednesday'
            when 4 then 'Thursday'
            when 5 then 'Friday'
            when 6 then 'Saturday'
            when 7 then 'Sunday'
        end as day_name,

        {{ day_of_week_iso('date_day') }} in (6, 7) as is_weekend,

        cast({{ dbt.date_trunc('month', 'date_day') }} as date) as first_day_of_month,
        cast({{ dbt.date_trunc('quarter', 'date_day') }} as date) as first_day_of_quarter,

        case
            when extract(month from date_day) >= 7 then extract(year from date_day) + 1
            else extract(year from date_day)
        end as fiscal_year,
        -- fiscal Q1 = Jul-Sep
        mod(extract(quarter from date_day) + 1, 4) + 1 as fiscal_quarter

    from days
)

select * from enriched
