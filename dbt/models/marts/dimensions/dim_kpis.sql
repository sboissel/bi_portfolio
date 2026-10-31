select
    kpi_sk,
    kpi_name,
    kpi_short_name,
    is_baseline,
    period_label,
    period_date,
    actual_value,
    monthly_target,
    yearly_target
from {{ ref('stg_kpis') }}
