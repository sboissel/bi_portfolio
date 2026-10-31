with milestones as (

    select * from {{ ref('dim_milestones') }}

),

projects as (

    select
        project_id,
        project_name
    from {{ ref('dim_projects') }}

)

select
    milestones.milestone_sk,
    milestones.milestone_id,
    milestones.milestone_name as milestone,
    projects.project_name as project,
    milestones.planned_date as planned,
    milestones.actual_date as actual,
    milestones.days_variance as variance_days,
    milestones.status = 'On Time' as on_time,
    milestones.status
from milestones
inner join projects
    on milestones.project_id = projects.project_id
