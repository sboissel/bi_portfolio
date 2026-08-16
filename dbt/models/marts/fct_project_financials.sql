with budgets as (

    select
        project_id,
        cost_category,
        planned_amount
    from {{ ref('dim_budgets') }}

),

spend as (

    select
        project_id,
        cost_category,
        spend_date,
        spend_month,
        actual_amount
    from {{ ref('dim_spend') }}

),

installments as (

    select
        spend.project_id,
        spend.cost_category,
        spend.spend_month,
        spend.actual_amount,
        budgets.planned_amount
        / count(*) over (
            partition by spend.project_id, spend.cost_category
        ) as planned_amount
    from spend
    inner join budgets
        on spend.project_id = budgets.project_id
        and spend.cost_category = budgets.cost_category

),

monthly as (

    select
        project_id,
        cost_category,
        spend_month as month,
        sum(planned_amount) as planned,
        sum(actual_amount) as actual
    from installments
    group by 1, 2, 3

),

projects as (

    select
        project_id,
        project_name
    from {{ ref('dim_projects') }}

)

select
    md5(concat_ws('|', monthly.month, monthly.project_id, monthly.cost_category)) as project_financials_sk,
    monthly.month,
    projects.project_name as project,
    monthly.cost_category,
    round(monthly.planned, 2) as planned,
    round(monthly.actual, 2) as actual,
    round(monthly.actual - monthly.planned, 2) as variance
from monthly
inner join projects
    on monthly.project_id = projects.project_id
