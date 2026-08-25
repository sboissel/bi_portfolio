with source as (

    select * from {{ source('raw', 'projects') }}

),

date_offset as (

    select offset_days
    from {{ ref('int_date_offset') }}

),

renamed as (

    select
        project_id::integer as project_id,
        trim(project_name) as project_name,
        trim(project_type) as project_type,
        trim(priority) as priority,
        trim(status) as status,
        date_add(
            'day',
            date_offset.offset_days,
            start_date::date
        ) as start_date,

        date_add(
            'day',
            date_offset.offset_days,
            end_date::date
        ) as end_date,

        budget_total::decimal(18, 2) as budget_total
    from source
    cross join date_offset

)

select * from renamed
