from datetime import date, timedelta

import pandas as pd
import pytest

from data_generation import (
    AS_OF_DATE,
    EXPECTED_CSV_NAMES,
    ProjectEntry,
    generate_actuals,
    generate_data,
    generate_resource_allocation,
    generate_targets,
    generate_task,
    generate_time_logs,
    kpi_list,
    n_projects,
    n_tasks,
    project_types,
    status_simulator,
    task_duration_ranges,
    task_types,
)


TASK_STATUSES = {"Not Started", "In Progress", "Done", "Cancelled"}


@pytest.fixture
def task_types_df():
    return pd.DataFrame(
        [[i, name, team] for i, (name, team) in enumerate(task_types.items())],
        columns=["task_type_id", "task_type_name", "default_team"],
    )


@pytest.fixture
def resources_df():
    rows = []
    resource_id = 0
    for team in sorted({team for team in task_types.values()}):
        rows.append([resource_id, f"Person {resource_id}", team, "Scientist", 30.0])
        resource_id += 1
        rows.append([resource_id, f"Person {resource_id}", team, "Scientist", 30.0])
        resource_id += 1
    return pd.DataFrame(
        rows,
        columns=["resource_id", "name", "team", "role", "capacity_hours_per_week"],
    )


def _task_dict(**overrides):
    base = {
        "task_id": 1,
        "project_id": 0,
        "task_type_id": 0,
        "task_type_name": "DNA Assembly",
        "start_date": date(2026, 1, 5),
        "due_date": date(2026, 1, 9),
        "status": "In Progress",
        "estimated_hours": 20,
    }
    base.update(overrides)
    return base


def _allocation_dict(**overrides):
    base = {
        "resource_id": 7,
        "project_id": 3,
        "task_id": 11,
        "status": "In Progress",
        "start_date": date(2026, 1, 5),
        "completion_date": date(2026, 1, 9),
        "planned_hours": 10.0,
    }
    base.update(overrides)
    return base


class TestStatusSimulator:
    def test_far_future_is_not_started(self):
        due = AS_OF_DATE + timedelta(days=31)
        assert status_simulator(due) == "Not Started"

    def test_far_past_is_closed(self):
        due = AS_OF_DATE - timedelta(days=31)
        statuses = {status_simulator(due) for _ in range(80)}
        assert statuses <= {"Done", "Cancelled"}
        assert "Not Started" not in statuses
        assert "In Progress" not in statuses


class TestGenerateTask:
    def test_uses_task_id_and_valid_enums(self):
        row = generate_task(42)
        (
            task_id,
            project_id,
            task_name,
            task_type_id,
            task_type_name,
            status,
            start_date,
            _days_since_start,
            due_date,
            _days_to_due,
            completion_date,
            estimated_hours,
        ) = row

        assert task_id == 42
        assert task_name == "Task 42"
        assert 0 <= project_id < n_projects
        assert task_type_name in task_types
        assert list(task_types.keys())[task_type_id] == task_type_name
        assert status in TASK_STATUSES
        assert due_date >= start_date
        min_dur, max_dur = task_duration_ranges[task_type_name]
        duration = (due_date - start_date).days
        assert min_dur <= duration <= max_dur
        assert min_dur <= estimated_hours <= max_dur * 7
        if status == "Done":
            assert completion_date is not None
            assert completion_date <= AS_OF_DATE
        else:
            assert completion_date is None


class TestGenerateResourceAllocation:
    def test_unassigned_returns_empty(self, monkeypatch, task_types_df, resources_df):
        monkeypatch.setattr("data_generation.random.choices", lambda *args, **kwargs: [False])
        assert generate_resource_allocation(_task_dict(), task_types_df, resources_df) == []

    def test_assigned_resources_come_from_default_team(
        self, monkeypatch, task_types_df, resources_df
    ):
        monkeypatch.setattr("data_generation.random.choices", lambda *args, **kwargs: [True])
        team = task_types_df.loc[0, "default_team"]
        team_ids = set(
            resources_df.loc[resources_df["team"] == team, "resource_id"]
        )

        rows = generate_resource_allocation(_task_dict(), task_types_df, resources_df)
        assert 1 <= len(rows) <= 3
        for row in rows:
            resource_id, task_id, project_id, task_type_name, alloc_team, *_rest, allocation, planned_hours = row
            assert resource_id in team_ids
            assert task_id == 1
            assert project_id == 0
            assert task_type_name == "DNA Assembly"
            assert alloc_team == team
            assert 0 < allocation <= 1
            assert planned_hours == pytest.approx(allocation * 20)


class TestGenerateTimeLogs:
    def test_not_started_has_no_logs(self):
        assert generate_time_logs(_allocation_dict(status="Not Started")) == []

    def test_cancelled_has_no_logs(self):
        assert generate_time_logs(_allocation_dict(status="Cancelled")) == []

    def test_weekend_only_range_is_empty(self):
        logs = generate_time_logs(
            _allocation_dict(
                status="Done",
                start_date=date(2026, 1, 3),  # Saturday
                completion_date=date(2026, 1, 4),  # Sunday
            )
        )
        assert logs == []

    def test_in_progress_logs_weekdays_through_as_of(self):
        start = date(2026, 4, 27)  # Monday
        logs = generate_time_logs(_allocation_dict(status="In Progress", start_date=start))
        dates = [row[3].date() if hasattr(row[3], "date") else row[3] for row in logs]
        assert dates
        assert dates[0] == start
        assert dates[-1] == AS_OF_DATE  # Friday 2026-05-01
        assert all(d.weekday() < 5 for d in dates)
        assert all(row[0] == 7 and row[1] == 3 and row[2] == 11 for row in logs)


class TestKpiSeries:
    def test_targets_are_linear(self):
        kpi = ProjectEntry(name="demo", baseline=0.0, target=12.0)
        targets = generate_targets(kpi)
        assert targets == [float(month) for month in range(1, 13)]

    def test_actuals_have_twelve_numeric_values(self):
        values = generate_actuals(kpi_list[0])
        assert len(values) == 12
        assert all(isinstance(v, float) for v in values)


class TestGenerateData:
    def test_writes_expected_csvs_and_invariants(self, tmp_path):
        frames = generate_data(tmp_path)

        assert set(frames) == set(EXPECTED_CSV_NAMES)
        for name in EXPECTED_CSV_NAMES:
            assert (tmp_path / f"{name}.csv").exists()

        projects = frames["projects"]
        tasks = frames["tasks"]
        resources = frames["resources"]
        allocations = frames["allocations"]
        time_logs = frames["time_logs"]
        budgets = frames["budgets"]
        spend = frames["spend"]
        milestones = frames["milestones"]
        kpis = frames["kpis"]

        assert len(projects) == n_projects
        assert len(tasks) == n_tasks
        assert projects["project_id"].is_unique
        assert tasks["task_id"].is_unique
        assert resources["resource_id"].is_unique
        assert resources["name"].is_unique
        assert set(projects["project_type"]) <= set(project_types)
        assert set(projects["priority"]) <= {"High", "Medium", "Low"}
        assert set(projects["status"]) <= {"On Track", "At Risk", "Delayed"}
        assert set(tasks["status"]) <= TASK_STATUSES
        assert tasks["project_id"].isin(projects["project_id"]).all()
        assert allocations["task_id"].isin(tasks["task_id"]).all()
        assert allocations["resource_id"].isin(resources["resource_id"]).all()
        assert allocations["allocation"].between(0, 1).all()
        assert time_logs["task_id"].isin(tasks["task_id"]).all()
        if not time_logs.empty:
            log_dates = pd.to_datetime(time_logs["date"])
            assert (log_dates.dt.weekday < 5).all()
        assert len(budgets) == n_projects * 2
        assert set(budgets["cost_category"]) == {"Labor", "External"}
        assert set(spend["cost_category"]) == {"Labor", "External"}
        spend_dates = pd.to_datetime(spend["date"])
        spend_window = spend.assign(date=spend_dates).merge(
            projects[["project_id", "start_date", "end_date"]], on="project_id"
        )
        assert (spend_window["date"] > pd.to_datetime(spend_window["start_date"])).all()
        assert (spend_window["date"] <= pd.to_datetime(spend_window["end_date"])).all()
        assert (spend_dates <= pd.Timestamp(AS_OF_DATE)).all()
        assert (spend["actual_amount"] >= 0).all()
        assert len(milestones) == 50
        as_of = pd.Timestamp("2026-04-06")
        completed = milestones["actual_date"].notna()
        assert (pd.to_datetime(milestones.loc[completed, "actual_date"]) < as_of).all()
        delayed = completed & (
            pd.to_datetime(milestones["actual_date"])
            > pd.to_datetime(milestones["planned_date"])
        )
        on_time = completed & ~delayed
        upcoming = milestones["actual_date"].isna()
        assert (milestones.loc[delayed, "status"] == "Delayed").all()
        assert (milestones.loc[on_time, "status"] == "On Time").all()
        assert (milestones.loc[upcoming, "status"] == "Upcoming").all()
        assert len(kpis) == len(kpi_list) * 13
        period_rows = kpis[kpis["month"].ne("Baseline")].copy()
        months = pd.to_datetime(period_rows["month"])
        assert period_rows.loc[months >= "2026-04-01", "actual_value"].isna().all()
        assert period_rows.loc[months < "2026-04-01", "actual_value"].notna().all()
