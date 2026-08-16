with projects as (

    select * from {{ ref('dim_projects') }}

),

task_metrics as (

    select
        project_id,
        count(*) as task_count,
        count(*) filter (where is_done) as tasks_completed,
        count(*) filter (where status = 'In Progress') as tasks_in_progress,
        count(*) filter (where is_cancelled) as tasks_cancelled,
        count(*) filter (where is_overdue) as tasks_overdue
    from {{ ref('dim_tasks') }}
    group by 1

),

hour_metrics as (

    select
        project_id,
        count(distinct resource_id) as resource_count,
        sum(planned_hours) as planned_hours
    from {{ ref('dim_allocations') }}
    where status != 'Cancelled'
    group by 1

),

actual_hours as (

    select
        project_id,
        sum(actual_hours) as actual_hours
    from {{ ref('dim_time_logs') }}
    group by 1

),

milestone_metrics as (

    select
        project_id,
        count(*) as milestone_count,
        count(*) filter (where not is_delayed) as milestones_on_time,
        count(*) filter (where is_delayed) as milestones_delayed
    from {{ ref('dim_milestones') }}
    group by 1

),

budget_metrics as (

    select
        project_id,
        sum(planned_amount) as budget_planned,
        sum(planned_amount) filter (where cost_category = 'Labor') as budget_planned_labor,
        sum(planned_amount) filter (where cost_category = 'External') as budget_planned_external
    from {{ ref('dim_budgets') }}
    group by 1

),

spend_metrics as (

    select
        project_id,
        sum(actual_amount) as budget_actual,
        sum(actual_amount) filter (where cost_category = 'Labor') as budget_actual_labor,
        sum(actual_amount) filter (where cost_category = 'External') as budget_actual_external
    from {{ ref('dim_spend') }}
    group by 1

)

select
    projects.project_sk,
    projects.project_id,
    projects.project_name,
    projects.project_type,
    projects.priority,
    projects.status,
    projects.start_date,
    projects.end_date,
    projects.duration_days,

    coalesce(task_metrics.task_count, 0) as task_count,
    coalesce(task_metrics.tasks_completed, 0) as tasks_completed,
    coalesce(task_metrics.tasks_in_progress, 0) as tasks_in_progress,
    coalesce(task_metrics.tasks_overdue, 0) as tasks_overdue,
    round(
        task_metrics.tasks_completed
        / nullif(task_metrics.task_count - task_metrics.tasks_cancelled, 0),
        4
    ) as task_completion_pct,

    coalesce(hour_metrics.resource_count, 0) as resource_count,
    round(coalesce(hour_metrics.planned_hours, 0), 2) as planned_hours,
    round(coalesce(actual_hours.actual_hours, 0), 2) as actual_hours,
    round(
        (coalesce(actual_hours.actual_hours, 0) - coalesce(hour_metrics.planned_hours, 0))
        / nullif(hour_metrics.planned_hours, 0),
        4
    ) as hours_variance_pct,

    coalesce(milestone_metrics.milestone_count, 0) as milestone_count,
    coalesce(milestone_metrics.milestones_on_time, 0) as milestones_on_time,
    coalesce(milestone_metrics.milestones_delayed, 0) as milestones_delayed,
    round(
        milestone_metrics.milestones_on_time
        / nullif(milestone_metrics.milestone_count, 0),
        4
    ) as on_time_milestone_pct,

    round(coalesce(budget_metrics.budget_planned, 0), 2) as budget_planned,
    round(coalesce(budget_metrics.budget_planned_labor, 0), 2) as budget_planned_labor,
    round(coalesce(budget_metrics.budget_planned_external, 0), 2) as budget_planned_external,
    round(coalesce(spend_metrics.budget_actual, 0), 2) as budget_actual,
    round(coalesce(spend_metrics.budget_actual_labor, 0), 2) as budget_actual_labor,
    round(coalesce(spend_metrics.budget_actual_external, 0), 2) as budget_actual_external,
    round(
        coalesce(spend_metrics.budget_actual, 0) - coalesce(budget_metrics.budget_planned, 0),
        2
    ) as budget_variance,
    round(
        (coalesce(spend_metrics.budget_actual, 0) - coalesce(budget_metrics.budget_planned, 0))
        / nullif(budget_metrics.budget_planned, 0),
        4
    ) as budget_variance_pct
from projects
left join task_metrics
    on projects.project_id = task_metrics.project_id
left join hour_metrics
    on projects.project_id = hour_metrics.project_id
left join actual_hours
    on projects.project_id = actual_hours.project_id
left join milestone_metrics
    on projects.project_id = milestone_metrics.project_id
left join budget_metrics
    on projects.project_id = budget_metrics.project_id
left join spend_metrics
    on projects.project_id = spend_metrics.project_id
