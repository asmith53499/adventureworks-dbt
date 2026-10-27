with source as (
    select * from {{ ref('currency_rate') }}
),

renamed as (
    select
        currency_rate_id,
        from_currency_code,
        to_currency_code,
        cast(cast(currency_rate_date as timestamp) as date) as currency_rate_date,
        cast(average_rate as numeric(19, 4)) as average_rate,
        cast(end_of_day_rate as numeric(19, 4)) as end_of_day_rate,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
