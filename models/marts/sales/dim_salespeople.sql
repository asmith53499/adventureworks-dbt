with sales_persons as (
    select * from {{ ref('stg_adventureworks__sales_persons') }}
),

persons as (
    select * from {{ ref('stg_adventureworks__persons') }}
),

employees as (
    select * from {{ ref('stg_adventureworks__employees') }}
),

territories as (
    select * from {{ ref('stg_adventureworks__sales_territories') }}
),

final as (
    select
        sales_persons.sales_person_id,
        persons.full_name as sales_person_name,
        employees.job_title,
        employees.hire_date,
        employees.is_current as is_current_employee,

        -- null territory = manager/unassigned rep without a territory of their own
        sales_persons.territory_id,
        territories.territory_name,
        territories.territory_group,

        sales_persons.current_sales_quota,
        sales_persons.bonus,
        sales_persons.commission_pct

    from sales_persons
    inner join persons
        on sales_persons.sales_person_id = persons.person_id
    inner join employees
        on sales_persons.sales_person_id = employees.employee_id
    left join territories
        on sales_persons.territory_id = territories.territory_id
)

select * from final
