with source as (
    select * from {{ ref('employee') }}
),

renamed as (
    select
        business_entity_id as employee_id,
        job_title,
        organization_level,
        cast(cast(hire_date as timestamp) as date) as hire_date,
        cast(salaried_flag as boolean) as is_salaried,
        cast(current_flag as boolean) as is_current,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
