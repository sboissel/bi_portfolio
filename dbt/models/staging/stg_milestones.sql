with source as (

    select * from {{ source('raw', 'milestones') }}

),

renamed as (

    select
        milestone_id::integer as milestone_id,
        project_id::integer as project_id,
        trim(milestone_name) as milestone_name,
        planned_date::date as planned_date,
        actual_date::date as actual_date,
        trim(status) as status
    from source

)

select * from renamed
