with tasks as (

    select * from {{ ref('dim_tasks') }}

),

projects as (

    select
        project_id,
        project_name
    from {{ ref('dim_projects') }}

),

task_types as (

    select
        task_type_id,
        default_team
    from {{ ref('dim_task_types') }}

),

actuals as (

    select
        task_id,
        sum(actual_hours) as actual_hours,
        min(log_date) as first_logged_date,
        max(log_date) as last_logged_date
    from {{ ref('dim_time_logs') }}
    group by 1

)

select
    tasks.task_sk,
    tasks.task_id,
    tasks.task_name as task,
    projects.project_name as project,
    tasks.task_type_name as type,
    task_types.default_team as team,
    tasks.status,
    tasks.start_date as planned_start_date,
    tasks.due_date as planned_due_date,
    actuals.first_logged_date as actual_start_date,
    coalesce(tasks.completion_date, actuals.last_logged_date) as actual_end_date,
    round(tasks.estimated_hours, 2) as estimated_hours,
    round(coalesce(actuals.actual_hours, 0), 2) as actual_hours,
    round(
        coalesce(actuals.actual_hours, 0) - tasks.estimated_hours,
        2
    ) as hour_variance,
    date_diff('day', tasks.start_date, tasks.due_date) as planned_days,
    case
        when tasks.completion_date is not null
            then date_diff('day', tasks.start_date, tasks.completion_date)
        when tasks.status = 'In Progress'
            then date_diff('day', tasks.start_date, '{{ var("as_of_date") }}'::date)
    end as actual_days,
    case
        when tasks.completion_date is not null
            then (
                select count(*)
                from generate_series(
                    tasks.start_date,
                    tasks.completion_date,
                    interval '1 day'
                ) as gs(work_date)
                where isodow(gs.work_date) <= 5
            )
    end as cycle_time
from tasks
left join projects
    on tasks.project_id = projects.project_id
left join task_types
    on tasks.task_type_id = task_types.task_type_id
left join actuals
    on tasks.task_id = actuals.task_id
