select
    md5(milestone_id::varchar) as milestone_sk,
    milestone_id,
    project_id,
    milestone_name,
    planned_date,
    actual_date,
    status,
    variance_days as days_variance,
    status in ('Delayed', 'Overdue') as is_delayed
from {{ ref('stg_milestones') }}
