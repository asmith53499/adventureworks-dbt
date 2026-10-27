with source as (
    select * from {{ ref('currency') }}
),

renamed as (
    select
        currency_code,
        name as currency_name,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
