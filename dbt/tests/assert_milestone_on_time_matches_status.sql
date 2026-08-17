-- on_time must match status.
select *
from {{ ref('fct_milestone_performance') }}
where (status = 'On Time' and not on_time)
   or (status = 'Delayed' and on_time)
