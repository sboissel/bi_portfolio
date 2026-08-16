select
    kpi_sk,
    kpi_name as kpi,
    period_date as month,
    round(actual_value, 4) as actual,
    round(monthly_target, 4) as monthly_target,
    round(actual_value - monthly_target, 4) as variance
from {{ ref('dim_kpis') }}
where not is_baseline
