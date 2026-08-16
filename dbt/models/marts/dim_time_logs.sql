select
    time_log_sk,
    resource_name,
    project_id,
    log_date,
    date_trunc('week', log_date)::date as week_start,
    actual_hours
from {{ ref('stg_time_logs') }}
