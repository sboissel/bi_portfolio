# Export the dbt models that the Tableau dashboards use to CSV files.
#
# Tableau Public Edition can only connect to files, not to DuckDB, so this is
# the step between `dbt build` and Tableau:
#
#     data_generation.py -> create_database.py -> dbt build -> export_for_tableau.py
#
# The staging views shift dates relative to today, so each export is a snapshot
# as of the day it runs. Re-run it before refreshing or republishing in Tableau.
import argparse
from pathlib import Path

import duckdb

REPO_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = REPO_ROOT / "data" / "biotech_ops.duckdb"
EXPORT_DIR = REPO_ROOT / "data" / "exports"

# One CSV per entry: file name -> query. Extra columns that Tableau would
# otherwise need custom SQL for are added here, since a text connection
# can't run SQL.
EXPORTS = {
    "int_project_health": "SELECT * FROM int_project_health",
    "stg_milestones": "SELECT * FROM stg_milestones",
    "int_kpi_scorecard": """
        SELECT
            *,
            strftime(month, '%b %y') AS month_label,
            CASE kpi_short_name
                WHEN 'On-Time %' THEN 1
                WHEN 'Utilization %' THEN 2
                WHEN 'Budget Var %' THEN 3
                ELSE 4
            END AS kpi_order
        FROM int_kpi_scorecard
    """,
}


def _quote(identifier):
    return '"' + identifier.replace('"', '""') + '"'


def _with_plain_dates(con, query):
    """Wrap a query so timestamp columns are written as dates (YYYY-MM-DD).

    The date shift adds an interval, which turns dates into timestamps; Tableau
    would otherwise read them as date-times with a midnight time.
    """
    columns = con.execute(f"DESCRIBE {query}").fetchall()
    select_list = []
    for name, column_type, *_ in columns:
        quoted = _quote(name)
        if column_type.upper().startswith("TIMESTAMP"):
            select_list.append(f"CAST({quoted} AS DATE) AS {quoted}")
        else:
            select_list.append(quoted)
    return f"SELECT {', '.join(select_list)} FROM ({query}) AS src"


def export_for_tableau(db_path=None, out_dir=None, exports=None):
    """Write each export to <out_dir>/<name>.csv and return {name: row count}."""
    db_path = Path(db_path) if db_path is not None else DB_PATH
    out_dir = Path(out_dir) if out_dir is not None else EXPORT_DIR
    exports = exports if exports is not None else EXPORTS

    if not db_path.exists():
        raise FileNotFoundError(f"No database at {db_path}. Run create_database.py and dbt build first.")
    out_dir.mkdir(parents=True, exist_ok=True)

    try:
        con = duckdb.connect(str(db_path), read_only=True)
    except duckdb.IOException as error:
        raise RuntimeError(
            f"Could not open {db_path}. Close anything else using it "
            "(a Tableau JDBC connection, a notebook, a dbt run) and try again."
        ) from error

    counts = {}
    try:
        for name, query in exports.items():
            out_path = out_dir / f"{name}.csv"
            final_query = _with_plain_dates(con, query)
            sql_path = str(out_path).replace("'", "''")
            con.execute(f"COPY ({final_query}) TO '{sql_path}' (HEADER, DELIMITER ',')")
            counts[name] = con.execute(f"SELECT COUNT(*) FROM ({query}) AS src").fetchone()[0]
            print(f"  {name}: {counts[name]} rows -> {out_path}")
    finally:
        con.close()

    print(f"Exported {len(counts)} tables to {out_dir}")
    return counts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DB_PATH, help="DuckDB file to read")
    parser.add_argument("--out", type=Path, default=EXPORT_DIR, help="folder for the CSV files")
    args = parser.parse_args()
    export_for_tableau(db_path=args.db, out_dir=args.out)
