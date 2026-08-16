with source as (

    select * from {{ source('raw', 'resources') }}

),

renamed as (

    select
        md5(resource_id::varchar) as resource_sk,
        resource_id::integer as resource_id,
        trim(name) as resource_name,
        trim(team) as team,
        trim(role) as role,
        capacity_hours_per_week::decimal(10, 2) as capacity_hours_per_week
    from source

)

select * from renamed
