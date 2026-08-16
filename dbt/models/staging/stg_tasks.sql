with source as (

    select * from {{ source('raw', 'tasks') }}

),

renamed as (

    select
        task_id::integer as task_id,
        project_id::integer as project_id,
        trim(task_name) as task_name,
        task_type_id::integer as task_type_id,
        trim(task_type_name) as task_type_name,
        trim(status) as status,
        start_date::date as start_date,
        days_since_start::integer as days_since_start,
        due_date::date as due_date,
        days_to_due::integer as days_to_due,
        completion_date::date as completion_date,
        estimated_hours::decimal(18, 2) as estimated_hours
    from source

)

select * from renamed
