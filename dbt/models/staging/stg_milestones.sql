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
        end as actual_date,
        
        trim(status) as status
    from source
    cross join date_offset

)

select
    *,
    date_diff('day', planned_date, actual_date) as variance_days
from renamed
