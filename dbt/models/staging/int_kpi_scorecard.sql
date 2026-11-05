-- Monthly KPI scorecard: actuals calculated from the operational tables, against
-- leadership targets from the kpi_targets seed.
--
-- Actuals are calculated on the raw (unshifted) dates, so calendar months line up
-- with how the data was generated: spend is booked at month ends, and a day-based
-- shift would push each booking into the following month. The finished months are
-- then relabelled forward by whole months, so they line up with the shifted
-- dashboards (the raw as-of month becomes the current month).

with anchor as (

    select
        (current_date - offset_days * interval '1 day')::date as as_of_raw,
        date_diff(
            'month',
            date_trunc('month', current_date - offset_days * interval '1 day'),
            date_trunc('month', current_date)
        ) as month_shift
    from {{ ref('int_date_offset') }}

),

plan_months as (

    -- A 12-month target year starting with the first month of project activity.
    select
        r.plan_month,
        (date_trunc('month', min_start.start_date) + (r.plan_month - 1) * interval '1 month')::date as raw_month
    from (select min(start_date::date) as start_date from {{ source('raw', 'projects') }}) as min_start
    cross join range(1, 13) as r(plan_month)

),

complete_months as (

    -- Only finished months get an actual; the as-of month is still in progress.
    select
        plan_months.raw_month,
        least(last_day(plan_months.raw_month), anchor.as_of_raw) as eval_date
    from plan_months
    cross join anchor
    where plan_months.raw_month < date_trunc('month', anchor.as_of_raw)

),

on_time as (

    -- Share of milestones due (planned) in the month that were delivered on or before
    -- their planned date. Milestones not yet delivered count as misses, so a month
    -- with nothing delivered scores 0% rather than having no value.
    select
        'On-Time %' as kpi_short_name,
        date_trunc('month', planned_date::date)::date as raw_month,
        avg(
            case
                when actual_date is not null
                    and actual_date::date <= anchor.as_of_raw
                    and actual_date::date <= planned_date::date
                    then 1.0
                else 0.0
            end
        ) as actual,
        count(*) as sample_size
    from {{ source('raw', 'milestones') }}
    cross join anchor
    where planned_date::date <= anchor.as_of_raw
    group by 1, 2

),

task_cycle as (

    select
        date_trunc('month', completion_date::date)::date as raw_month,
        (
            select count(*)
            from generate_series(start_date::date, completion_date::date, interval '1 day') as gs(work_date)
            where isodow(gs.work_date) <= 5
        ) as working_days
    from {{ source('raw', 'tasks') }}
    cross join anchor
    where status = 'Done'
      and completion_date is not null
      and completion_date::date <= anchor.as_of_raw
      and completion_date::date >= start_date::date  -- a few generated tasks finish before they start

),

cycle_time as (

    -- Average working days from start to completion for tasks completed in the month.
    select
        'Cycle Time' as kpi_short_name,
        raw_month,
        avg(working_days) as actual,
        count(*) as sample_size
    from task_cycle
    group by 1, 2

),

utilization_hours as (

    select
        date_trunc('month', time_logs.date::date)::date as raw_month,
        sum(time_logs.actual_hours) as hours
    from {{ source('raw', 'time_logs') }} as time_logs
    cross join anchor
    where time_logs.date::date <= anchor.as_of_raw
    group by 1

),

utilization as (

    -- Logged hours as a share of the whole team's working capacity in the month.
    select
        'Utilization %' as kpi_short_name,
        utilization_hours.raw_month,
        utilization_hours.hours / (
            (select sum(capacity_hours_per_week) from {{ source('raw', 'resources') }})
            * (
                select count(*)
                from generate_series(
                    utilization_hours.raw_month,
                    last_day(utilization_hours.raw_month),
                    interval '1 day'
                ) as gs(work_date)
                where isodow(gs.work_date) <= 5
            ) / 5.0
        ) as actual,
        null::bigint as sample_size
    from utilization_hours

),

planned_to_date as (

    -- Budget each project should have used by the month end, straight-line over its schedule.
    select
        complete_months.raw_month,
        sum(
            projects.budget_total
            * least(greatest(
                date_diff('day', projects.start_date::date, complete_months.eval_date)
                / nullif(date_diff('day', projects.start_date::date, projects.end_date::date), 0),
                0), 1)
        ) as planned
    from complete_months
    cross join {{ source('raw', 'projects') }} as projects
    group by 1

),

spend_to_date as (

    select
        complete_months.raw_month,
        sum(spend.actual_amount) as spent
    from complete_months
    inner join {{ source('raw', 'spend') }} as spend
        on spend.date::date <= complete_months.eval_date
    group by 1

),

budget_variance as (

    -- Cumulative: (planned to date - spent to date) / planned to date.
    -- Negative means over budget, matching the target's sign convention.
    select
        'Budget Var %' as kpi_short_name,
        planned_to_date.raw_month,
        (planned_to_date.planned - coalesce(spend_to_date.spent, 0)) / nullif(planned_to_date.planned, 0) as actual,
        null::bigint as sample_size
    from planned_to_date
    left join spend_to_date
        on planned_to_date.raw_month = spend_to_date.raw_month

),

actuals as (

    select * from on_time
    union all
    select * from utilization
    union all
    select * from cycle_time
    union all
    select * from budget_variance

),

targets as (

    select * from {{ ref('kpi_targets') }}

),

scorecard as (

    select
        targets.kpi_name,
        targets.kpi_short_name,
        targets.unit,
        targets.better,
        plan_months.plan_month,
        (plan_months.raw_month + anchor.month_shift * interval '1 month')::date as month,
        case when complete_months.raw_month is not null then actuals.actual end as actual,
        case when complete_months.raw_month is not null then actuals.sample_size end as sample_size,
        targets.baseline + (targets.year_goal - targets.baseline) * plan_months.plan_month / 12.0 as monthly_target,
        targets.baseline,
        targets.year_goal,
        targets.upper_limit,
        current_date as as_of_date
    from targets
    cross join plan_months
    cross join anchor
    left join complete_months
        on plan_months.raw_month = complete_months.raw_month
    left join actuals
        on targets.kpi_short_name = actuals.kpi_short_name
        and plan_months.raw_month = actuals.raw_month

)

select
    md5(concat_ws('|', kpi_short_name, plan_month)) as kpi_scorecard_sk,
    *,
    actual - monthly_target as variance_to_target,
    case
        when actual is null then null
        when upper_limit is not null and actual > upper_limit then 'Over limit'
        when better = 'higher' and actual >= monthly_target then 'Ahead'
        when better = 'lower' and actual <= monthly_target then 'Ahead'
        else 'Behind'
    end as status,
    (actual - baseline) / nullif(year_goal - baseline, 0) as progress_to_goal,
    month = max(month) filter (where actual is not null) over (partition by kpi_short_name) as is_latest_actual
from scorecard
