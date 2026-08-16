select
    md5(milestone_id::varchar) as milestone_sk,
    milestone_id,
    project_id,
    milestone_name,
    planned_date,
    actual_date,
    status,
    date_diff('day', planned_date, actual_date) as days_variance,
    status = 'Delayed' as is_delayed
from {{ ref('stg_milestones') }}
