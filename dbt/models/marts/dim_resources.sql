select
    resource_sk,
    resource_id,
    resource_name,
    team,
    role,
    capacity_hours_per_week
from {{ ref('stg_resources') }}
