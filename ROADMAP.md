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

Prefer the dbt marts below over raw CSVs so dates and statuses match Tableau.

| Dashboard | What it answers | Source tables | Use these models |
| --- | --- | --- | --- |
| Capacity vs demand | Which teams or people are over- or under-allocated in the coming weeks? | `resources`, `allocations` | `dim_resources`, `fct_resource_allocation`, `fct_resource_utilization` |
| Utilization | Actual logged hours vs capacity, by person and team | `resources`, `time_logs` | `fct_resource_utilization` |
| Task backlog & aging | What’s overdue, what’s stuck, and where does work pile up by task type? | `tasks`, `task_types` | `fct_task_performance`, `dim_tasks`, `dim_task_types` |
| Estimate accuracy | How far are estimated hours from actual hours, by task type and team? | `tasks`, `time_logs` | `fct_task_performance` |
| What-if planner | If we add project X or lose a person, which teams break? | `resources`, `allocations` | Load the same tables, then recompute in Streamlit |

**What-if planner is the centerpiece.** Sliders and inputs change capacity or demand and the app recalculates live. The first version answers both halves of its question: remove a person or reduce their capacity, and add project X as hours of demand per team per week. The other four pages are read-only views that set up that question.

**App rules:**

- Filters: team, person, project, next N weeks. Default to the coming weeks, not the whole history.
- Formulas stay consistent with `src/metrics.md` (utilization = actual hours / capacity).
- Suggested layout: `app/Home.py` (what-if) plus pages for the four read-only views.

## 2. Right after the first app

- **DuckDB is single-writer.** Streamlit and Tableau should open `data/biotech_ops.duckdb` read-only, or use a copied extract. Close them before `create_database` or `dbt build`, or those jobs will fail to lock the file.
- **One refresh command.** A short script that runs `create_database` then `dbt build --project-dir dbt --profiles-dir dbt`.
- **Real CI.** `.gitlab-ci.yml` is still a Pages stub. Run `pytest` and `dbt build` (or parse + tests against a CI DuckDB) on every push.
- **Ignore junk.** Add `.DS_Store` and `__pycache__/` to `.gitignore`.
- **Demo notes.** How to refresh, how to start Streamlit, how to open Tableau, and two or three screenshots.

## 3. After that

- **What-if v2.** Model a new project by copying an existing project’s allocation pattern instead of entering its demand by hand, and remove a whole existing project.
- **At-risk teams.** From the planner, list teams that go over capacity in the next N weeks so the PMO page has a short action list.

## 4. Ask the data: natural-language questions + evaluation

An "Ask the data" page in the Streamlit app. A user types a question, an LLM writes SQL against the same dbt marts the other pages use, and the page shows the answer with the generated SQL.

- **Model: free only.** A free, rate-limited API tier (e.g. Gemini) for the hosted app, or a local open model via Ollama for development and live demos. Data is synthetic, so free-tier data terms are not a concern.
- **Evaluation set.** 30–50 questions with known correct answers, covering:
  - simple lookups and aggregations
  - time windows ("next 4 weeks"), with "today" pinned so answers are stable
  - project metrics (utilization, estimate accuracy) defined in `src/metrics.md`
  - ambiguous questions, where the right answer is a clarifying question
  - unanswerable questions, where the right answer is to say the data isn't there
- **Grading.** Compare query results, not SQL text. Log a failure reason for each miss (wrong join, wrong metric definition, misread time window).
- **Before/after.** Run the evaluation with schema only, then with metric definitions added, and report accuracy by category in the README.
- **Demo safety.** Keep the hosted page within free-tier rate limits; offer example questions alongside free-text input.

## Suggested order

1. Streamlit read-only pages: utilization, backlog & aging, estimate accuracy
2. Capacity vs demand, then the what-if planner (lose a person, add project X)
3. Refresh command, GitLab CI, gitignore, demo notes
4. What-if v2 (project templates, remove a project) and at-risk teams
5. Ask the data: evaluation question set first, then the page, then the before/after run