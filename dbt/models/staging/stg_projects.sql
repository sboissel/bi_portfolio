with source as (

    select * from {{ source('raw', 'projects') }}

),

renamed as (

    select
        project_id::integer as project_id,
        trim(project_name) as project_name,
        trim(project_type) as project_type,
        trim(priority) as priority,
        trim(status) as status,
        start_date::date as start_date,
        end_date::date as end_date,
        budget_total::decimal(18, 2) as budget_total
    from source

)

select * from renamed
