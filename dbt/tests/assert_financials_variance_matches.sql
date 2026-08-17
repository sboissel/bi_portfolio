-- variance must equal actual minus planned.
select *
from {{ ref('fct_project_financials') }}
where round(actual - planned, 2) != round(variance, 2)
