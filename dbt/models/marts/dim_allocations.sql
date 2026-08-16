select
    allocation_sk,
    resource_sk,
    resource_name,
    task_id,
    project_id,
    task_type_name,
    team,
    start_date,
    due_date,
    status,
    allocation,
    planned_hours
from {{ ref('stg_allocations') }}
