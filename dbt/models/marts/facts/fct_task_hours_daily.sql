with tasks as (

    select * from {{ ref('fct_task_performance') }}

),

planned_days as (

    select
        tasks.task_id,
        gs.work_date::date as work_date,
        tasks.estimated_hours
        / (date_diff('day', tasks.planned_start_date, tasks.planned_due_date) + 1)
            as planned_hours
    from tasks,
        generate_series(
            tasks.planned_start_date,
            tasks.planned_due_date,
            interval '1 day'
        ) as gs(work_date)
    where tasks.planned_start_date is not null
      and tasks.planned_due_date is not null
      and tasks.planned_start_date <= tasks.planned_due_date

),

actual_days as (

    select
        tasks.task_id,
        gs.work_date::date as work_date,
        tasks.actual_hours
        / (date_diff('day', tasks.actual_start_date, tasks.actual_end_date) + 1)
            as actual_hours
    from tasks,
        generate_series(
            tasks.actual_start_date,
            tasks.actual_end_date,
            interval '1 day'
        ) as gs(work_date)
    where tasks.actual_start_date is not null
      and tasks.actual_end_date is not null
      and tasks.actual_start_date <= tasks.actual_end_date

),

dates as (

    select task_id, work_date from planned_days
    union
    select task_id, work_date from actual_days

)

select
    md5(concat_ws('|', dates.task_id, dates.work_date)) as task_hours_daily_sk,
    dates.work_date,
    date_trunc('month', dates.work_date)::date as month,
    tasks.task_id,
    tasks.task,
    tasks.project,
    tasks.type,
    tasks.team,
    tasks.status,
    round(coalesce(planned_days.planned_hours, 0), 2) as planned_hours,
    round(coalesce(actual_days.actual_hours, 0), 2) as actual_hours
from dates
inner join tasks
    on dates.task_id = tasks.task_id
left join planned_days
    on dates.task_id = planned_days.task_id
    and dates.work_date = planned_days.work_date
left join actual_days
    on dates.task_id = actual_days.task_id
    and dates.work_date = actual_days.work_date
