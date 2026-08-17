# dbt project (`bi_portfolio`)

Transforms the DuckDB database at `../data/biotech_ops.duckdb` (profile `bi_portfolio` in `profiles.yml`).

Run from this directory (`dbt/`), not the repo root:

```bash
dbt build --profiles-dir .
```

From the repo root:

```bash
dbt build --project-dir dbt --profiles-dir dbt
```

`as_of_date` is `2026-05-01` (see `dbt_project.yml`). Recreating the DuckDB file drops these models; run `dbt build` again after `python src/create_database.py`.

## Models

| Path | Materialization | Role |
| --- | --- | --- |
| `models/staging/` | view | One `stg_*` model per raw CSV table |
| `models/marts/dimensions/` | table | `dim_*` attributes |
| `models/marts/facts/` | table | `fct_*` metrics (utilization, task/project performance, financials, KPIs) |

Column descriptions and generic tests live next to the models (`_stg.yml`, `_dims.yml`, `_facts.yml`).

## Tests

- **Generic:** unique, not-null, `accepted_values`, and `relationships` on staging and marts
- **Singular:** `tests/` (allocation bounds, variance formulas, milestone status, date weekday/weekend)
- **Unit:** `models/marts/facts/_unit_tests.yml` (task performance statuses, financials planned-spread)

```bash
dbt test --profiles-dir . --select "test_type:unit"
dbt test --profiles-dir . --select staging marts
```
