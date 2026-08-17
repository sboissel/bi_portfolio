-- When an actual exists, variance must equal actual minus monthly target.
select *
from {{ ref('fct_kpi_monthly') }}
where actual is not null
  and round(actual - monthly_target, 4) != round(variance, 4)
