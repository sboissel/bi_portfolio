with source as (

    select * from {{ source('raw', 'time_logs') }}

),

date_offset as (

    select offset_days
    from {{ ref('int_date_offset') }}

),

shifted as (

    select
        resource_id::integer as resource_id,
        project_id::integer as project_id,
        task_id::integer as task_id,

        date_add(
            'day',
            date_offset.offset_days,
            date::date
        ) as log_date,

        actual_hours::decimal(18, 2) as actual_hours

    from source
    cross join date_offset

),

numbered as (

    select
        *,
        row_number() over (
            partition by resource_id, project_id, task_id, log_date
            order by actual_hours
        ) as row_num
    from shifted

),

renamed as (

    select
        md5(
            concat_ws(
                '|',
                resource_id,
                project_id,
                task_id,
                log_date,
                row_num
            )
        ) as time_log_sk,

        resource_id,
        project_id,
        task_id,
        log_date,
        actual_hours

    from numbered

)

select * from renamed