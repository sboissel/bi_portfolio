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
        date_add(
            'day',
            date_offset.offset_days,
            planned_date::date
        ) as planned_date,
        
        date_add(
            'day',
            date_offset.offset_days,
            actual_date::date
        ) as actual_date,
        
        trim(status) as status
    from source
    cross join date_offset

)

select * from renamed
