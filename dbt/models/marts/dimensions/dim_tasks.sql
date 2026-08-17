select
    md5(task_id::varchar) as task_sk,
    task_id,
    project_id,
    task_name,
    task_type_id,
    task_type_name,
    status,
    start_date,
    days_since_start,
    due_date,
    days_to_due,
    completion_date,
    estimated_hours,
    status = 'Done' as is_done,
    status = 'Cancelled' as is_cancelled,
    status not in ('Done', 'Cancelled') and days_to_due < 0 as is_overdue
from {{ ref('stg_tasks') }}
