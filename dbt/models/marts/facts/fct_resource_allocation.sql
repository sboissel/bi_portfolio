with allocations as (

    select * from {{ ref('dim_allocations') }}

),

tasks as (

    select
        task_id,
        task_name
    from {{ ref('dim_tasks') }}

),

projects as (

    select
        project_id,
        project_name
    from {{ ref('dim_projects') }}

),

resources as (

    select
        resource_id,
        resource_name
    from {{ ref('dim_resources') }}

)

select
    allocations.allocation_sk,
    allocations.resource_sk,
    resources.resource_name as resource,
    tasks.task_name as task,
    projects.project_name as project,
    allocations.allocation,
    round(allocations.planned_hours, 2) as planned_hours
from allocations
inner join resources
    on allocations.resource_id = resources.resource_id
inner join tasks
    on allocations.task_id = tasks.task_id
inner join projects
    on allocations.project_id = projects.project_id
