with resources as (

    select * from {{ ref('stg_resources') }}

),

allocations as (

    select * from {{ ref('stg_allocations') }}
    where start_date <= due_date
      and status != 'Cancelled'

),

time_logs as (

    select * from {{ ref('stg_time_logs') }}

),

allocation_weekdays as (

    select
        a.allocation_sk,
        a.resource_name,
        gs.work_date::date as work_date,
        a.planned_hours
    from allocations as a,
        generate_series(a.start_date, a.due_date, interval '1 day') as gs(work_date)
    where isodow(gs.work_date) <= 5

),

allocation_days as (

    select
        resource_name,
        work_date,
        planned_hours / count(*) over (partition by allocation_sk) as planned_hours_daily
    from allocation_weekdays

),

planned_weekly as (

    select
        date_trunc('week', work_date)::date as week_start,
        resource_name,
        sum(planned_hours_daily) as planned
    from allocation_days
    group by 1, 2

),

actual_weekly as (

    select
        date_trunc('week', log_date)::date as week_start,
        resource_name,
        sum(actual_hours) as actual
    from time_logs
    group by 1, 2

),

weeks as (

    select week_start from planned_weekly
    union
    select week_start from actual_weekly

),

spine as (

    select
        weeks.week_start,
        resources.resource_name,
        resources.team,
        resources.capacity_hours_per_week as capacity
    from weeks
    cross join resources

)

select
    md5(concat_ws('|', spine.week_start, spine.resource_name)) as resource_utilization_sk,
    spine.week_start as week,
    spine.resource_name as resource,
    spine.team,
    spine.capacity,
    round(coalesce(planned_weekly.planned, 0), 2) as planned,
    round(coalesce(actual_weekly.actual, 0), 2) as actual,
    round(
        coalesce(actual_weekly.actual, 0) / nullif(spine.capacity, 0),
        4
    ) as utilization
from spine
left join planned_weekly
    on spine.week_start = planned_weekly.week_start
    and spine.resource_name = planned_weekly.resource_name
left join actual_weekly
    on spine.week_start = actual_weekly.week_start
    and spine.resource_name = actual_weekly.resource_name
