with source as (
    select * from {{ ref('customer') }}
),

renamed as (
    select
        customer_id,
        -- exactly one of person_id / store_id identifies an individual or reseller;
        -- store customers may also carry person_id for their store contact
        person_id,
        store_id,
        territory_id,
        account_number,
        cast(modified_date as timestamp) as modified_at

    from source
)

select * from renamed
