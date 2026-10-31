# Roadmap

This repo already has a full path from synthetic CSVs to DuckDB, dbt marts, tests, and Tableau. Next is a **Delivery & Resource Operations** Streamlit app for team leads and the PMO — people managing work and capacity week to week.

Tableau stays the portfolio / plan-vs-actual tool. Streamlit is for operations logic: calculations and what-if inputs that a drag-and-drop BI tool cannot do well.

## Already in place

- Synthetic generator, DuckDB load, dbt staging + dimensions + facts
- Plan vs actual at project, task, milestone, hours, spend, and KPI grain
- Date shift so the snapshot stays current relative to today
- pytest and dbt tests
- Tableau can connect to `data/biotech_ops.duckdb`

## 1. Streamlit: Delivery & Resource Operations

Read from DuckDB **read-only** (or a copied extract). Prefer the dbt marts below over raw CSVs so dates and statuses match Tableau.

| Dashboard | What it answers | Source tables | Use these models |
| --- | --- | --- | --- |
| Capacity vs demand | Which teams or people are over- or under-allocated in the coming weeks? | `resources`, `allocations` | `dim_resources`, `fct_resource_allocation`, `fct_resource_utilization` |
| Utilization | Actual logged hours vs capacity, by person and team | `resources`, `time_logs` | `fct_resource_utilization` |
| Task backlog & aging | What’s overdue, what’s stuck, and where does work pile up by task type? | `tasks`, `task_types` | `fct_task_performance`, `dim_tasks`, `dim_task_types` |
| Estimate accuracy | How far are estimated hours from actual hours, by task type and team? | `tasks`, `time_logs` | `fct_task_performance` |
| What-if planner | If we add project X or lose a person, which teams break? | `resources`, `allocations` | Load the same tables, then recompute in Streamlit |

**What-if planner is the centerpiece.** Sliders and inputs change capacity or demand and the app recalculates live. The other four pages are read-only views that set up that question.

**App rules:**

- Open DuckDB read-only so Tableau and dbt do not lock the file.
- Filters: team, person, project, next N weeks. Default to the coming weeks, not the whole history.
- Formulas stay consistent with `src/metrics.md` (utilization = actual hours / capacity).
- Suggested layout: `app/Home.py` (what-if) plus pages for the four read-only views.

## 2. Right after the first app

- **One refresh command.** A short script that runs `create_database` then `dbt build --project-dir dbt --profiles-dir dbt`. Document “close Tableau / Streamlit first.”
- **Real CI.** `.gitlab-ci.yml` is still a Pages stub. Run `pytest` and `dbt build` (or parse + tests against a CI DuckDB) on every push.
- **Ignore junk.** Add `.DS_Store` and `__pycache__/` to `.gitignore`.
- **Demo notes.** How to refresh, how to start Streamlit, how to open Tableau, and two or three screenshots.

## 3. After that

- **What-if v2.** Add or remove a whole project (reuse an existing project’s allocation pattern), not only one person or a capacity slider.
- **At-risk teams.** From the planner, list teams that go over capacity in the next N weeks so the PMO page has a short action list.

## Not recommended

- Rebuilding the Tableau portfolio dashboard in Streamlit
- Airflow, Snowflake, or a warehouse migration
- Auth or write-back into DuckDB
- Recreating every fact table in the app — stay on the five views above

## Suggested order

1. Streamlit read-only pages: utilization, backlog & aging, estimate accuracy
2. Capacity vs demand, then the what-if planner
3. Refresh command, GitLab CI, gitignore, demo notes
4. What-if v2 (add/remove a project) and at-risk teams
