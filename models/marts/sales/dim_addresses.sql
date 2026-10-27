-- Bill-to / ship-to addresses with their geography, for slicing sales by location.

select * from {{ ref('int_addresses__geography') }}
