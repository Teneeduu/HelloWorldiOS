"""Generate a throwaway plan.json so CI can screenshot the planner with real rows."""

import json
import uuid
from datetime import datetime, timezone

now = datetime.now(timezone.utc)
midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)


def stamp(moment):
    return moment.strftime("%Y-%m-%dT%H:%M:%SZ")


def task(title, minutes, done=False):
    row = {
        "id": str(uuid.uuid4()).upper(),
        "title": title,
        "day": stamp(midnight),
        "status": "done" if done else "todo",
        "estimateMinutes": minutes,
        "createdAt": stamp(now),
    }
    if done:
        row["doneAt"] = stamp(now)
    return row


plan = [
    task("写完季度报告", 120),
    task("读书第 3-4 章", 50, done=True),
    task("跑步 5 公里", 30),
]

with open("sample-plan.json", "w", encoding="utf-8") as f:
    json.dump(plan, f, ensure_ascii=False, indent=2)
