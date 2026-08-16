select
    md5(task_type_id::varchar) as task_type_sk,
    task_type_id,
    task_type_name,
    default_team
from {{ ref('stg_task_types') }}
