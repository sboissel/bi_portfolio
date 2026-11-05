import duckdb
import pytest

from export_for_tableau import export_for_tableau


def _make_db(path):
    con = duckdb.connect(str(path))
    try:
        con.execute(
            "CREATE TABLE milestones AS "
            "SELECT 1 AS milestone_id, TIMESTAMP '2026-11-01 00:00:00' AS planned_date, 'On Time' AS status "
            "UNION ALL "
            "SELECT 2, TIMESTAMP '2026-12-15 00:00:00', 'Upcoming'"
        )
    finally:
        con.close()


def test_missing_database_raises(tmp_path):
    with pytest.raises(FileNotFoundError, match="No database"):
        export_for_tableau(db_path=tmp_path / "missing.duckdb", out_dir=tmp_path / "out")


def test_writes_one_csv_per_export_with_plain_dates(tmp_path):
    db_path = tmp_path / "ops.duckdb"
    _make_db(db_path)
    out_dir = tmp_path / "exports"

    counts = export_for_tableau(
        db_path=db_path,
        out_dir=out_dir,
        exports={"milestones": "SELECT * FROM milestones ORDER BY milestone_id"},
    )

    assert counts == {"milestones": 2}
    lines = (out_dir / "milestones.csv").read_text().splitlines()
    assert lines[0] == "milestone_id,planned_date,status"
    assert lines[1] == "1,2026-11-01,On Time"
    assert lines[2] == "2,2026-12-15,Upcoming"
