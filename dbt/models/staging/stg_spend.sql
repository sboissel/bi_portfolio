with source as (

    select * from {{ source('raw', 'spend') }}

),

date_offset as (

    select offset_days
    from {{ ref('int_date_offset') }}

),

renamed as (

    select
        md5(concat_ws('|', project_id, date, cost_category)) as spend_sk,
        project_id::integer as project_id,
        
        date_add(
            'day',
            date_offset.offset_days,
            date::date
        ) as spend_date,

        trim(cost_category) as cost_category,
        actual_amount::decimal(18, 2) as actual_amount
    from source
    cross join date_offset

)

select * from renamed
