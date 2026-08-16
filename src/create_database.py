# Load CSVs from data/raw into a DuckDB database.
import duckdb
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = REPO_ROOT / "data" / "raw"
DB_PATH = REPO_ROOT / "data" / "biotech_ops.duckdb"


def create_database():
    csv_files = sorted(RAW_DIR.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in {RAW_DIR}")

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()

    con = duckdb.connect(str(DB_PATH))
    try:
        for csv_path in csv_files:
            table_name = csv_path.stem
            con.execute(
                f'CREATE TABLE "{table_name}" AS SELECT * FROM read_csv(?, header = true, auto_detect = true)',
                [str(csv_path)],
            )
            n = con.execute(f'SELECT COUNT(*) FROM "{table_name}"').fetchone()[0]
            print(f"  {table_name}: {n} rows")
    finally:
        con.close()

    print(f"Database created at {DB_PATH}")


if __name__ == "__main__":
    create_database()
