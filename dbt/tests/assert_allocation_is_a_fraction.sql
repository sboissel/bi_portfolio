-- Allocation is a share of a task, so it must sit between 0 and 1.
select *
from {{ ref('stg_allocations') }}
where allocation < 0
   or allocation > 1
