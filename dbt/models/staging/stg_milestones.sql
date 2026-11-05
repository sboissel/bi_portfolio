with source as (

    select * from {{ source('raw', 'milestones') }}

),

date_offset as (

    select offset_days
    from {{ ref('int_date_offset') }}

),

renamed as (

    select
        milestone_id::integer as milestone_id,
        project_id::integer as project_id,
        trim(milestone_name) as milestone_name,
        planned_date::date + (date_offset.offset_days * interval '1 day') as planned_date,
        case
            when actual_date is null then null
            else actual_date::date + (date_offset.offset_days * interval '1 day')
        end as actual_date
    from source
    cross join date_offset

),

-- Status is derived against today rather than taken from the CSV, whose
-- statuses were set against a fixed cutoff and go stale as the date shift
-- moves. Actual dates after today are treated as not yet delivered.
as_of_today as (

    select
        milestone_id,
        project_id,
        milestone_name,
        planned_date,
        case when actual_date::date <= current_date then actual_date end as actual_date
    from renamed

)

select
    *,
    case
        when actual_date is not null and actual_date > planned_date then 'Delayed'
        when actual_date is not null then 'On Time'
        when planned_date::date < current_date then 'Overdue'
        else 'Upcoming'
    end as status,
    date_diff('day', planned_date, actual_date) as variance_days
from as_of_today
