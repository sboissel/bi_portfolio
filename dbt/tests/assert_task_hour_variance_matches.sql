-- hour_variance must equal actual_hours minus estimated_hours.
select *
from {{ ref('fct_task_performance') }}
where round(actual_hours - estimated_hours, 2) != round(hour_variance, 2)
