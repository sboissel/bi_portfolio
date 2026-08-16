with source as (

    select * from {{ source('raw', 'task_types') }}

),

renamed as (

    select
        task_type_id::integer as task_type_id,
        trim(task_type_name) as task_type_name,
        trim(default_team) as default_team
    from source

)

select * from renamed
