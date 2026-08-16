select
    md5(project_id::varchar) as project_sk,
    project_id,
    project_name,
    project_type,
    priority,
    status,
    start_date,
    end_date,
    budget_total,
    date_diff('day', start_date, end_date) as duration_days
from {{ ref('stg_projects') }}
