select
    spend_sk,
    project_id,
    spend_date,
    date_trunc('month', spend_date)::date as spend_month,
    cost_category,
    actual_amount
from {{ ref('stg_spend') }}
