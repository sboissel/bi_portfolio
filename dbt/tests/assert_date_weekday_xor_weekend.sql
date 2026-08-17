-- A date is a weekday or a weekend, never both or neither.
select *
from {{ ref('dim_date') }}
where is_weekday = is_weekend
