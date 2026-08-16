# Biotech Portfolio Dataset

Synthetic project-management data for a biotech R&D portfolio dashboard. The generator models a mid-size lab organization running strain development, process optimization, assay development, platform, and customer programs.

All data is fictional. It is meant for BI prototypes, dashboard mockups, and analysis practice — not as a record of real work.

## What's included

```
src/data_generation.py   # generator
data/                    # exported CSVs
requirements.txt         # pandas, numpy
```

The snapshot is frozen as of **2026-05-01** (about four months after the portfolio start date of 2026-01-01). Task status, time logs, and KPI actuals are simulated relative to that date.

## Dataset

| File | Description |
| --- | --- |
| `projects.csv` | 12 projects: type, priority, status, dates, total budget |
| `resources.csv` | People by team and role, with weekly capacity (hours) |
| `task_types.csv` | Work types (e.g. DNA Assembly, Fermentation Run) and default team |
| `tasks.csv` | 200 tasks with status, dates, and estimated hours |
| `allocations.csv` | Resource assignments to tasks (fraction of effort and planned hours) |
| `time_logs.csv` | Weekday actual hours for in-progress and completed work |
| `budgets.csv` | Planned Labor vs External spend per project |
| `spend.csv` | Monthly actual spend by cost category |
| `milestones.csv` | Planned vs actual milestone dates |
| `kpis.csv` | Monthly portfolio KPIs with baseline, target, and actuals through Q1 |

**Project types:** Strain Development, Process Optimization, Assay Development, Platform Build, Customer Program

**Teams:** Strain Engineering, Molecular Biology, Analytical, Process Development, Data Science, Automation, Quality, Program Management

**Portfolio KPIs:** on-time milestone delivery, resource utilization, budget variance, cycle time, quality success rate

Budgets split roughly 60% labor / 40% external. Spend and logged hours include some overrun so variance analysis is interesting.

## Generate data

Python 3 with pandas and numpy:

```bash
pip install -r requirements.txt
python src/data_generation.py
```

This overwrites the CSVs in `data/`. Scale, dates, teams, and task types are configured at the top of `src/data_generation.py`.
