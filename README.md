# Biotech Portfolio Dataset

Synthetic project-management data for a biotech R&D portfolio dashboard. The generator models a mid-size lab organization running strain development, process optimization, assay development, platform, and customer programs.

All data is fictional. It is meant for BI prototypes, dashboard mockups, and analysis practice — not as a record of real work.

## What's included

```
src/data_generation.py   # CSV generator
src/create_database.py   # load CSVs into DuckDB
tests/                   # pytest for the Python scripts
dbt/                     # staging views and mart tables (dims + facts)
data/raw/                # exported CSVs
data/biotech_ops.duckdb  # DuckDB database
requirements.txt         # pandas, numpy, duckdb, dbt, pytest
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

This overwrites the CSVs in `data/raw/`. Scale, dates, teams, and task types are configured at the top of `src/data_generation.py`.

Load those CSVs into DuckDB (one table per file, named after the CSV stem):

```bash
python src/create_database.py
```

This replaces `data/biotech_ops.duckdb`.

Build staging views and mart tables in that same database, then run tests. The dbt project lives in `dbt/`, so a bare `dbt build` from the repo root will fail looking for `dbt_project.yml` here.

```bash
cd dbt
dbt build --profiles-dir .
```

From the repo root instead:

```bash
dbt build --project-dir dbt --profiles-dir dbt
```

See `dbt/README.md` for model layout and test types. Always pass `--profiles-dir` so dbt uses the local DuckDB profile (`dbt/profiles.yml`), not `~/.dbt`.

Python tests (from the repo root) cover the generator helpers, CSV output invariants, and the DuckDB loader. They write to a temporary directory and do not replace `data/raw/` or `data/biotech_ops.duckdb`.

```bash
pytest
```

## Development environment (pyenv)

This project uses `pyenv` rather than a virtualenv. Set the local Python version with `pyenv` and install dependencies into that interpreter.

Steps:

```bash
# install the desired Python (if not already installed)
pyenv install 3.14.4
# set local version for the project (creates .python-version)
pyenv local 3.14.4
# install dependencies into the pyenv-managed interpreter
python -m pip install -r requirements.txt
# run generators and DB loader using the pyenv python
python src/data_generation.py
python src/create_database.py
pytest
cd dbt && dbt build --profiles-dir .
```

Do not create or activate a `venv` for this project; using `pyenv local` ensures the correct interpreter is used when you run `python` commands.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
