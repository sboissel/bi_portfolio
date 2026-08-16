select
    budget_sk,
    project_id,
    cost_category,
    planned_amount
from {{ ref('stg_budgets') }}
