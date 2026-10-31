with source as (

    select * from {{ source('raw', 'kpis') }}

),

renamed as (

    select
        md5(concat_ws('|', kpi_name, month)) as kpi_sk,
        trim(kpi_name) as kpi_name,
        case trim(kpi_name)
            when 'On-Time Milestone Delivery (%)' then 'On-Time %'
            when 'Resource Utilization (%)' then 'Utilization %'
            when 'Budget Variance (%)' then 'Budget Var %'
            when 'Cycle Time (days)' then 'Cycle Time'
            when 'Quality Success Rate (%)' then 'Quality %'
        end as kpi_short_name,
        month = 'Baseline' as is_baseline,
        month as period_label,
        case
            when month = 'Baseline' then null
            else try_cast(month as date)
                + (
                    (year(current_date) - year(try_cast(month as date)))
                    * interval '1 year'
                )
        end as period_date,
        
        actual_value::decimal(18, 6) as actual_value,
        monthly_target::decimal(18, 6) as monthly_target,
        yearly_target::decimal(18, 6) as yearly_target
    from source

)

select * from renamed
