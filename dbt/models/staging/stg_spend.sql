with source as (

    select * from {{ source('raw', 'spend') }}

),

renamed as (

    select
        md5(concat_ws('|', project_id, date, cost_category)) as spend_sk,
        project_id::integer as project_id,
        date::date as spend_date,
        trim(cost_category) as cost_category,
        actual_amount::decimal(18, 2) as actual_amount
    from source

)

select * from renamed
