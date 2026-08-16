with source as (

    select * from {{ source('raw', 'allocations') }}

),

renamed as (

    select
        md5(concat_ws('|', resource_id, task_id)) as allocation_sk,
        md5(resource_id::varchar) as resource_sk,
        resource_id::integer as resource_id,
        task_id::integer as task_id,
        project_id::integer as project_id,
        trim(task_type_name) as task_type_name,
        trim(team) as team,
        start_date::date as start_date,
        completion_date::date as due_date,
        trim(status) as status,
        allocation::decimal(8, 4) as allocation,
        planned_hours::decimal(18, 2) as planned_hours
    from source

)

select * from renamed
