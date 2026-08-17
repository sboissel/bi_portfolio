import duckdb
import pandas as pd
import pytest

from create_database import create_database
from data_generation import generate_data


def test_missing_csvs_raise(tmp_path):
    with pytest.raises(FileNotFoundError, match="No CSV files found"):
        create_database(raw_dir=tmp_path, db_path=tmp_path / "out.duckdb")


def test_loads_each_csv_as_a_table(tmp_path):
    raw = tmp_path / "raw"
    raw.mkdir()
    pd.DataFrame({"id": [1, 2], "name": ["a", "b"]}).to_csv(raw / "items.csv", index=False)
    pd.DataFrame({"item_id": [1], "qty": [3]}).to_csv(raw / "orders.csv", index=False)

    db_path = tmp_path / "ops.duckdb"
    create_database(raw_dir=raw, db_path=db_path)

    assert db_path.exists()
    con = duckdb.connect(str(db_path), read_only=True)
    try:
        tables = {row[0] for row in con.execute("SHOW TABLES").fetchall()}
        assert tables == {"items", "orders"}
        assert con.execute("SELECT COUNT(*) FROM items").fetchone()[0] == 2
        assert con.execute("SELECT COUNT(*) FROM orders").fetchone()[0] == 1
        assert con.execute("SELECT name FROM items ORDER BY id").fetchall() == [("a",), ("b",)]
    finally:
        con.close()


def test_replaces_an_existing_database(tmp_path):
    raw = tmp_path / "raw"
    raw.mkdir()
    db_path = tmp_path / "ops.duckdb"
    pd.DataFrame({"id": [1]}).to_csv(raw / "items.csv", index=False)
    create_database(raw_dir=raw, db_path=db_path)

    pd.DataFrame({"id": [1, 2, 3]}).to_csv(raw / "items.csv", index=False)
    create_database(raw_dir=raw, db_path=db_path)

    con = duckdb.connect(str(db_path), read_only=True)
    try:
        assert con.execute("SELECT COUNT(*) FROM items").fetchone()[0] == 3
    finally:
        con.close()


def test_loads_generated_portfolio(tmp_path):
    raw = tmp_path / "raw"
    db_path = tmp_path / "biotech_ops.duckdb"
    frames = generate_data(raw)
    create_database(raw_dir=raw, db_path=db_path)

    con = duckdb.connect(str(db_path), read_only=True)
    try:
        tables = {row[0] for row in con.execute("SHOW TABLES").fetchall()}
        assert tables == set(frames)
        for name, df in frames.items():
            count = con.execute(f'SELECT COUNT(*) FROM "{name}"').fetchone()[0]
            assert count == len(df)
    finally:
        con.close()
