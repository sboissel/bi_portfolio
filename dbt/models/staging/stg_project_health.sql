-- One row per project with budget burn vs schedule progress, as of today.
-- Built on the staged (date-shifted) models, so as_of_date = current_date
-- lines up with the shifted project and spend dates.

with projects as (

    select * from {{ ref('stg_projects') }}

),

spend as (

    select
        project_id,
        sum(actual_amount) as spend_total,
        sum(actual_amount) filter (where spend_date::date <= current_date) as spend_to_date
    from {{ ref('stg_spend') }}
    group by 1

),

milestones as (

    -- Status is re-derived against today so it stays correct as the date shift moves.
    select
        project_id,
        count(*) filter (where actual_date::date <= current_date or planned_date::date < current_date) as milestones_due,
        count(*) filter (where actual_date::date <= current_date and actual_date <= planned_date) as milestones_on_time,
        count(*) filter (where actual_date::date <= current_date and actual_date > planned_date) as milestones_delivered_late,
        count(*) filter (
            where (actual_date is null or actual_date::date > current_date)
              and planned_date::date < current_date
        ) as milestones_overdue,
        coalesce(
            sum(date_diff('day', planned_date::date, actual_date::date))
                filter (where actual_date::date <= current_date and actual_date > planned_date),
            0
        ) as late_days_total
    from {{ ref('stg_milestones') }}
    group by 1

),

progress as (

    select
        projects.project_id,
        projects.project_name,
        projects.project_type,
        projects.priority,
        projects.status as reported_status,
        projects.start_date::date as start_date,
        projects.end_date::date as end_date,
        projects.budget_total,
        current_date as as_of_date,

        coalesce(spend.spend_to_date, 0) as spend_to_date,
        coalesce(spend.spend_total, 0) as spend_total,

        coalesce(spend.spend_to_date, 0) / nullif(projects.budget_total, 0) as pct_budget_spent,

        least(
            greatest(
                date_diff('day', projects.start_date::date, current_date)
                / nullif(date_diff('day', projects.start_date::date, projects.end_date::date), 0),
                0
            ),
            1
        ) as pct_schedule_elapsed,

        coalesce(milestones.milestones_due, 0) as milestones_due,
        coalesce(milestones.milestones_on_time, 0) as milestones_on_time,
        coalesce(milestones.milestones_delivered_late, 0) as milestones_delivered_late,
        coalesce(milestones.milestones_overdue, 0) as milestones_overdue,
        coalesce(milestones.late_days_total, 0) as late_days_total

    from projects
    left join spend
        on projects.project_id = spend.project_id
    left join milestones
        on projects.project_id = milestones.project_id

)

select
    *,
    pct_budget_spent - pct_schedule_elapsed as burn_gap,
    case
        when pct_budget_spent - pct_schedule_elapsed > 0.15 then 'Overspending'
        when pct_budget_spent - pct_schedule_elapsed > 0.05 then 'Watch'
        else 'OK'
    end as budget_health,
    case
        when current_date < start_date then 'Not started'
        when current_date > end_date then 'Past end date'
        else 'In flight'
    end as schedule_phase
from progress
