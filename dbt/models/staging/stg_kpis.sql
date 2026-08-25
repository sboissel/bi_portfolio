with source as (

    select * from {{ source('raw', 'kpis') }}

),

renamed as (

    select
        md5(concat_ws('|', kpi_name, month)) as kpi_sk,
        trim(kpi_name) as kpi_name,
        month = 'Baseline' as is_baseline,
        month as period_label,
        case
            when month = 'Baseline' then null
            else date_add(
                'year',
                year(current_date) - year(try_cast(month as date)),
                try_cast(month as date)
            )
        end as period_date,
        
        actual_value::decimal(18, 6) as actual_value,
        monthly_target::decimal(18, 6) as monthly_target,
        yearly_target::decimal(18, 6) as yearly_target
    from source

)

select * from renamed
