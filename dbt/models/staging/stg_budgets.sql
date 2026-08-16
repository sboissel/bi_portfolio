with source as (

    select * from {{ source('raw', 'budgets') }}

),

renamed as (

    select
        md5(concat_ws('|', project_id, cost_category)) as budget_sk,
        project_id::integer as project_id,
        trim(cost_category) as cost_category,
        planned_amount::decimal(18, 2) as planned_amount
    from source

)

select * from renamed
