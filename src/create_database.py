# Load CSVs from data/raw into a DuckDB database.
import duckdb
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = REPO_ROOT / "data" / "raw"
DB_PATH = REPO_ROOT / "data" / "biotech_ops.duckdb"


def create_database(raw_dir=None, db_path=None):
    raw_dir = Path(raw_dir) if raw_dir is not None else RAW_DIR
    db_path = Path(db_path) if db_path is not None else DB_PATH

    csv_files = sorted(raw_dir.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in {raw_dir}")

    db_path.parent.mkdir(parents=True, exist_ok=True)
    if db_path.exists():
        db_path.unlink()

    con = duckdb.connect(str(db_path))
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

    print(f"Database created at {db_path}")
    return db_path


if __name__ == "__main__":
    create_database()
