-- Each product should have at most one cost record in effect on any date,
-- otherwise the costed order lines would fan out.

select
    earlier.product_id,
    earlier.valid_from as earlier_valid_from,
    later.valid_from as later_valid_from

from {{ ref('stg_adventureworks__product_cost_histories') }} as earlier
inner join {{ ref('stg_adventureworks__product_cost_histories') }} as later
    on earlier.product_id = later.product_id
    and earlier.valid_from < later.valid_from
where earlier.valid_to is null
    or earlier.valid_to >= later.valid_from
