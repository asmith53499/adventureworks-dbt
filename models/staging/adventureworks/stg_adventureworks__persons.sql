with source as (
    select * from {{ ref('person') }}
),

renamed as (
    select
        business_entity_id as person_id,

        person_type as person_type_code,
        case person_type
            when 'SC' then 'Store Contact'
            when 'IN' then 'Individual Customer'
            when 'SP' then 'Sales Person'
            when 'EM' then 'Employee'
            when 'VC' then 'Vendor Contact'
            when 'GC' then 'General Contact'
        end as person_type,

        title,
        first_name,
        middle_name,
        last_name,
        suffix,
        first_name || ' ' || last_name as full_name,

        -- 0 = no promotional email, 1 = AdventureWorks only, 2 = AdventureWorks and partners
        email_promotion as email_promotion_preference,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
