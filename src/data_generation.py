# This script generates synthetic data for a project management dashboard.
import pandas as pd
import numpy as np
from datetime import date, timedelta
import random
from pathlib import Path
from dataclasses import dataclass   

REPO_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = REPO_ROOT / "data" / "raw"

np.random.seed(42)

# -----------------------
# CONFIG
# -----------------------
n_projects = 12
n_tasks = 200

START_DATE = date(2026, 1, 1)
AS_OF_DATE = START_DATE + timedelta(days=120)  # simulate as if we're 4 months into the projects

project_types = [
    "Strain Development",
    "Process Optimization",
    "Assay Development",
    "Platform Build",
    "Customer Program"
]
teams = [
    "Strain Engineering",
    "Molecular Biology",
    "Analytical",
    "Process Development",
    "Data Science",
    "Automation",
    "Quality",
    "Program Management"
]
roles_by_team = {
    "Strain Engineering": ["Research Associate", "Scientist", "Senior Scientist"],
    "Molecular Biology": ["Research Associate", "Scientist"],
    "Analytical": ["Lab Technician", "Scientist"],
    "Process Development": ["Associate Engineer", "Engineer", "Senior Engineer"],
    "Data Science": ["Data Scientist"],
    "Automation": ["Automation Engineer"],
    "Quality": ["QA Specialist"],
    "Program Management": ["Program Manager"]
}
role_allocation_baseline = {
    "Research Associate": 0.9,
    "Scientist": 0.75,
    "Senior Scientist": 0.6,
    "Lab Technician": 0.9,
    "Associate Engineer": 0.9,
    "Engineer": 0.75,
    "Senior Engineer": 0.65,
    "Data Scientist": 0.7,
    "Automation Engineer": 0.8,
    "QA Specialist": 0.65,
    "Program Manager": 0.5
}
task_types = {
    "DNA Assembly": "Molecular Biology",
    "Strain Construction": "Strain Engineering",
    "PCR / Cloning": "Molecular Biology",
    "Fermentation Run": "Process Development",
    "Downstream Processing": "Process Development",
    "Assay Development": "Analytical",
    "Sample Testing": "Analytical",
    "Data Analysis": "Data Science",
    "Model Development": "Data Science",
    "Automation Workflow Setup": "Automation",
    "Lab Equipment Maintenance": "Automation",
    "Quality Review": "Quality",
    "Deviation Investigation": "Quality",
    "Project Planning": "Program Management",
    "Stakeholder Update": "Program Management"
}
task_duration_ranges = {
    "DNA Assembly": (2, 5),
    "PCR / Cloning": (1, 3),
    "Strain Construction": (10, 25),
    "Fermentation Run": (7, 20),
    "Downstream Processing": (5, 15),
    "Assay Development": (5, 12),
    "Sample Testing": (2, 7),
    "Data Analysis": (3, 10),
    "Model Development": (7, 20),
    "Automation Workflow Setup": (10, 30),
    "Lab Equipment Maintenance": (1, 5),
    "Quality Review": (2, 8),
    "Deviation Investigation": (5, 15),
    "Project Planning": (2, 6),
    "Stakeholder Update": (1, 2)
}

# -----------------------
# PROJECTS
# -----------------------
projects = []
for i in range(n_projects):
    s = START_DATE + timedelta(days=random.randint(0, 60))
    e = s + timedelta(days=random.randint(90, 180))
    budget = random.randint(100000, 500000)

    projects.append([
        i, f"Project {i}", random.choice(project_types),
        random.choice(["High", "Medium", "Low"]),
        random.choice(["On Track", "At Risk", "Delayed"]),
        s, e, budget
    ])

projects_df = pd.DataFrame(projects, columns=[
    "project_id", "project_name", "project_type", "priority", "status",
    "start_date", "end_date", "budget_total"
])

# -----------------------
# RESOURCES
# -----------------------
resources = []
for team in teams:
    for i in range(random.randint(2, 4)):  # 1-5 resources per team
        role = random.choice(roles_by_team[team])
        availability = role_allocation_baseline[role] * 40  # hours per week
        resources.append([
            i, f"Person {i}", team, role, availability
        ])

resources_df = pd.DataFrame(resources, columns=[
    "resource_id", "name", "team", "role", "capacity_hours_per_week"
])
n_resources = len(resources_df)

# -----------------------
# TASK TYPES
# -----------------------
task_types_df = pd.DataFrame([
    [i, name, team] for i, (name, team) in enumerate(task_types.items())
], columns=["task_type_id", "task_type_name", "default_team"])

# -----------------------
# TASKS
# -----------------------
def status_simulator(due_date):
    if due_date < AS_OF_DATE + timedelta(days=-30):
        # past tasks should be closed
        status = random.choices(
            ["Not Started", "In Progress", "Done", "Cancelled"],
            weights=[0, 0, 0.95, 0.05]
        )[0]

    elif AS_OF_DATE + timedelta(days=-30) <= due_date < AS_OF_DATE + timedelta(days=-10):
        # some recent tasks may still be in progress or just starting
        status = random.choices(
            ["Not Started", "In Progress", "Done", "Cancelled"],
            weights=[0.15, 0.25, 0.55, 0.05]
        )[0]

    elif AS_OF_DATE + timedelta(days=-10) <= due_date < AS_OF_DATE + timedelta(days=10):
        # approx execution window shoudld have a mix of statuses
        status = random.choices(
            ["Not Started", "In Progress", "Done", "Cancelled"],
            weights=[0.35, 0.35, 0.3, 0]
        )[0]

    elif AS_OF_DATE + timedelta(days=10) <= due_date < AS_OF_DATE + timedelta(days=30):
        # some upcoming tasks may have started, but most should be not started
        status = random.choices(
            ["Not Started", "In Progress", "Done", "Cancelled"],
            weights=[0.8, 0.15, 0.05, 0]
        )[0]

    else:
        # future work
        status = "Not Started"

    return status

def generate_task():
    project_id = random.randint(0, n_projects - 1)
    task_type_id = random.randint(0, len(task_types) - 1)

    s = START_DATE + timedelta(days=random.randint(0, 180))
    days_since_start = (AS_OF_DATE - s).days
    task_type_name = list(task_types.keys())[task_type_id]
    min_dur, max_dur = task_duration_ranges[task_type_name]
    duration = random.randint(min_dur, max_dur)
    due = s + timedelta(days=duration)
    days_to_due = (due - AS_OF_DATE).days
    status = status_simulator(due)
    completion_date = min(AS_OF_DATE, due + timedelta(days=random.randint(-5, 15))) if status == "Done" else None
    estimated_hours = random.randint(duration, duration*7)  # 1-7 hours per day of work

    return  [
        i, project_id, f"Task {i}", task_type_id, task_type_name,
        status, s, days_since_start, due, days_to_due, 
        completion_date, estimated_hours
    ]

tasks = []
for i in range(n_tasks):
    task = generate_task()
    tasks.append(task)
    
tasks_df = pd.DataFrame(tasks, columns=[
    "task_id", "project_id", "task_name", "task_type_id", 
    "task_type_name", "status", "start_date", "days_since_start", 
    "due_date", "days_to_due", "completion_date", "estimated_hours"
])

# -----------------------
# ALLOCATIONS
# -----------------------
def generate_resource_allocation(task_dict):
    assigned = random.choices([True, False], weights=[0.85, 0.15])[0]
    if not assigned: 
        return []  # no allocations for unassigned tasks

    # allocate 1-3 resources per task
    team = task_types_df.loc[task_dict["task_type_id"], "default_team"]
    team_resources = resources_df.loc[resources_df["team"] == team, "name"].tolist()
    n_alloc = random.randint(1, min(3, len(team_resources)))
    task_resources = random.sample(team_resources, n_alloc)
    resource_allocations = [x/20 for x in sorted(random.sample(range(1, 18), n_alloc))]
    estimated_hours = task_dict["estimated_hours"]

    alloc = 0
    task_allocations = []
    for r, a in zip(task_resources, resource_allocations):
        alloc = a - alloc  # incremental allocation
        planned_hours = alloc * estimated_hours  # scale by estimated hours and typical
        task_allocations.append([
            r, task_dict["task_id"], task_dict["project_id"], task_dict["task_type_name"],
            team, task_dict["start_date"], task_dict["due_date"], task_dict["status"], 
            round(alloc, 2), round(planned_hours, 2)
        ])
    
    return task_allocations
    
allocations = []
for _, row in tasks_df.iterrows():
    allocations.extend(generate_resource_allocation(row.to_dict()))

alloc_df = pd.DataFrame(allocations, columns=[
    "resource_name", "task_id", "project_id", "task_type_name", 
    "team", "start_date", "completion_date", "status", "allocation", 
    "planned_hours"
])

# -----------------------
# TIME LOGS (actuals)
# -----------------------

def generate_time_logs(allocation_dict):
    # only generate time logs for tasks that are in progress or done
    if allocation_dict["status"] not in ["In Progress", "Done"]:
        return []

    if allocation_dict["status"] == "In Progress":
        # for in progress tasks, log fractional time up to AS_OF_DATE
        start_date = allocation_dict["start_date"]
        end_date = AS_OF_DATE
        planned_hours = allocation_dict["planned_hours"]
        fraction_complete = random.randint(1, 9) / 10  # simulate 10-90% completion
        actual_hours = round(planned_hours * fraction_complete * np.random.normal(1.1, 0.3), 2)  # some overrun
    
    elif allocation_dict["status"] == "Done":
        # for done tasks, log time up to completion date
        start_date = allocation_dict["start_date"]
        end_date = allocation_dict["completion_date"]
        planned_hours = allocation_dict["planned_hours"]
        actual_hours = round(planned_hours * np.random.normal(1.1, 0.3), 2)  # some overrun
    
    task_logs = []
    # use pandas business day range length to avoid divide-by-zero
    bdays = len(pd.bdate_range(start=start_date, end=end_date))
    if bdays == 0:
        return task_logs
    daily_hours = actual_hours / bdays
    for single_date in pd.bdate_range(start=start_date, end=end_date):
        task_logs.append([
            allocation_dict["resource_name"], allocation_dict["project_id"],
            single_date, round(daily_hours, 2)
        ])

    return task_logs

time_logs = []
for _, row in alloc_df.iterrows():
    time_logs.extend(generate_time_logs(row.to_dict()))

time_logs_df = pd.DataFrame(time_logs, columns=[
    "resource_name", "project_id",
    "date", "actual_hours"
])

# -----------------------
# BUDGET & SPEND
# -----------------------
budgets = []
spend = []

for pid in range(n_projects):
    total = projects_df.loc[pid, "budget_total"]

    labor = int(total * 0.6)
    external = int(total * 0.4)

    budgets.append([pid, "Labor", labor])
    budgets.append([pid, "External", external])

    # spend slightly off
    for m in range(6):
        spend.append([
            pid,
            START_DATE + timedelta(days=30 * m),
            "Labor",
            int(labor / 6 * np.random.normal(1.1, 0.2))
        ])
        spend.append([
            pid,
            START_DATE + timedelta(days=30 * m),
            "External",
            int(external / 6 * np.random.normal(0.9, 0.2))
        ])

budgets_df = pd.DataFrame(budgets, columns=[
    "project_id", "cost_category", "planned_amount"
])

spend_df = pd.DataFrame(spend, columns=[
    "project_id", "date", "cost_category", "actual_amount"
])

# -----------------------
# MILESTONES
# -----------------------
milestones = []
for i in range(50):
    planned = START_DATE + timedelta(days=random.randint(30, 180))
    actual = planned + timedelta(days=random.randint(-10, 20))

    milestones.append([
        i,
        random.randint(0, n_projects - 1),
        f"Milestone {i}",
        planned,
        actual,
        "Delayed" if actual > planned else "On Time"
    ])

milestones_df = pd.DataFrame(milestones, columns=[
    "milestone_id", "project_id", "milestone_name",
    "planned_date", "actual_date", "status"
])

# -----------------------
# KPI (monthly)
# -----------------------
@dataclass
class ProjectEntry:
    name: str
    baseline: float
    target: float

milestone_kpis = ProjectEntry(  
    name="On-Time Milestone Delivery (%)",
    baseline=0.72,
    target=0.9
)
resource_util_kpis = ProjectEntry(
    name="Resource Utilization (%)",
    baseline=0.78,
    target=0.85
)
budget_var_kpis = ProjectEntry(
    name="Budget Variance (%)",
    baseline=-0.08,  # 8% over budget
    target=0.0     # on budget
)
cycle_time_kpis = ProjectEntry(     
    name="Cycle Time (days)",
    baseline=26,
    target=20
)
quality_kpis = ProjectEntry(
    name="Quality Success Rate (%)",
    baseline=0.72,
    target=0.8
)  
kpi_list = [milestone_kpis, resource_util_kpis, budget_var_kpis, cycle_time_kpis, quality_kpis]

def generate_targets(kpi):
    increment = (kpi.target - kpi.baseline)/12  # linear improvement towards target over 12 months
    return [kpi.baseline + increment * month for month in range(1, 13)]

def generate_actuals(kpi):
    actual = random.uniform(kpi.baseline, kpi.target * 1.1)
    increment = (actual - kpi.baseline)/12
    return [round(kpi.baseline + increment * month + random.uniform(-0.02, 0.02), 2) for month in range(1, 13)]

kpis = []
months = [date(2026, month, 1) for month in range(1, 13)]
for kpi in kpi_list:
    kpis.append([
        kpi.name,
        "Baseline",
        kpi.baseline,
        kpi.baseline,
        kpi.target
    ])
    targets = generate_targets(kpi)
    actuals = generate_actuals(kpi)

    for i, month in enumerate(months):
        target = targets[i]
        actual = actuals[i] if month < date(2026, 4, 1) else None # only generate actuals for current and past periods    
        kpis.append([
            kpi.name,
            month,
            actual,
            target,
            kpi.target
        ])

kpis_df = pd.DataFrame(kpis, columns=[
    "kpi_name", "month", "actual_value", 
    "monthly_target", "yearly_target"
])

# -----------------------
# EXPORT
# -----------------------
DATA_DIR.mkdir(parents=True, exist_ok=True)

projects_df.to_csv(DATA_DIR / "projects.csv", index=False)
tasks_df.to_csv(DATA_DIR / "tasks.csv", index=False)
resources_df.to_csv(DATA_DIR / "resources.csv", index=False)
task_types_df.to_csv(DATA_DIR / "task_types.csv", index=False)
alloc_df.to_csv(DATA_DIR / "allocations.csv", index=False)
time_logs_df.to_csv(DATA_DIR / "time_logs.csv", index=False)
budgets_df.to_csv(DATA_DIR / "budgets.csv", index=False)
spend_df.to_csv(DATA_DIR / "spend.csv", index=False)
milestones_df.to_csv(DATA_DIR / "milestones.csv", index=False)
kpis_df.to_csv(DATA_DIR / "kpis.csv", index=False)

print(f"Data generated in {DATA_DIR}")