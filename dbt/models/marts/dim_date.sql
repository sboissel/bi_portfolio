with date_points as (

    select start_date as date_day from {{ ref('stg_projects') }}
    union all
    select end_date from {{ ref('stg_projects') }}
    union all
    select start_date from {{ ref('stg_tasks') }}
    union all
    select due_date from {{ ref('stg_tasks') }}
    union all
    select completion_date from {{ ref('stg_tasks') }}
    union all
    select start_date from {{ ref('stg_allocations') }}
    union all
    select due_date from {{ ref('stg_allocations') }}
    union all
    select log_date from {{ ref('stg_time_logs') }}
    union all
    select spend_date from {{ ref('stg_spend') }}
    union all
    select planned_date from {{ ref('stg_milestones') }}
    union all
    select actual_date from {{ ref('stg_milestones') }}
    union all
    select period_date from {{ ref('stg_kpis') }}

),

bounds as (

    select
        date_trunc('week', min(date_day))::date as start_date,
        (
            date_trunc('year', max(date_day))
            + interval '1 year'
            - interval '1 day'
        )::date as end_date
    from date_points
    where date_day is not null

),

spine as (

    select gs.date_day::date as date_day
    from bounds,
        generate_series(bounds.start_date, bounds.end_date, interval '1 day') as gs(date_day)

)

select
    date_day,
    strftime(date_day, '%Y%m%d')::integer as date_key,
    extract(year from date_day)::integer as year,
    extract(quarter from date_day)::integer as quarter,
    extract(month from date_day)::integer as month,
    extract(day from date_day)::integer as day_of_month,
    isodow(date_day) as day_of_week,
    extract(week from date_day)::integer as iso_week,
    strftime(date_day, '%A') as day_name,
    strftime(date_day, '%a') as day_name_short,
    strftime(date_day, '%B') as month_name,
    strftime(date_day, '%b') as month_name_short,
    strftime(date_day, '%Y-%m') as year_month,
    'Q' || extract(quarter from date_day)::integer as quarter_label,
    date_trunc('week', date_day)::date as week_start,
    date_trunc('month', date_day)::date as month_start,
    date_trunc('quarter', date_day)::date as quarter_start,
    date_trunc('year', date_day)::date as year_start,
    isodow(date_day) <= 5 as is_weekday,
    isodow(date_day) >= 6 as is_weekend
from spine
