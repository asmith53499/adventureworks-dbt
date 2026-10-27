with special_offers as (
    select * from {{ ref('stg_adventureworks__special_offers') }}
),

final as (
    select
        special_offer_id,
        special_offer_description,
        special_offer_type,
        special_offer_category,
        discount_pct,
        min_quantity,
        max_quantity,
        start_date,
        end_date,
        -- offer 1 is the placeholder applied to every undiscounted line
        special_offer_id <> 1 as is_discounted

    from special_offers
)

select * from final
