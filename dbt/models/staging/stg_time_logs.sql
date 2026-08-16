with source as (

    select * from {{ source('raw', 'time_logs') }}

),

renamed as (

    select
        md5(concat_ws('|',
            resource_id,
            project_id,
            task_id,
            date,
            row_number() over (
                partition by resource_id, project_id, task_id, date
                order by actual_hours
            )
        )) as time_log_sk,
        resource_id::integer as resource_id,
        project_id::integer as project_id,
        task_id::integer as task_id,
        date::date as log_date,
        actual_hours::decimal(18, 2) as actual_hours
    from source

)

select * from renamed
