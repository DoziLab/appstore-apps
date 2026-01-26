#!/usr/bin/env python3
"""
Generate course_spec JSON and Base64 for env.yaml.

Defaults: 20 students, groups of 4 (5 DBs), teacher enabled.
Usage examples:
  python3 base64_erzeuger.py
  python3 base64_erzeuger.py --students 16 --group-size 4 --course-label sql-2026-02 --domain dozi.edu
"""

import argparse
import base64
import json
import math


def build_spec(args):
    course_label = args.course_label
    db_prefix = course_label.replace("-", "_")

    # groups
    num_groups = math.ceil(args.students / args.group_size)
    groups = {
        f"g{i:02d}": {"db_name": f"{db_prefix}_{i:02d}_g{i:02d}".replace("__", "_")}
        for i in range(1, num_groups + 1)
    }

    # users
    users = {}
    for idx in range(1, args.students + 1):
        group_idx = ((idx - 1) // args.group_size) + 1
        gid = f"g{group_idx:02d}"
        uid = f"s{idx:02d}"
        users[uid] = {
            "group": gid,
            "db_password": f"DbPw-{uid}-ChangeMe!",
            "pgadmin_email": f"{uid}@{args.domain}",
            "pgadmin_password": f"PgPw-{uid}-ChangeMe!",
        }

    teacher = {
        "enabled": not args.no_teacher,
        "db_user": "teacher",
        "db_password": "TeacherDbPw-ChangeMe!",
        "pgadmin_email": f"teacher@{args.domain}",
        "pgadmin_password": "TeacherPgPw-ChangeMe!",
    }

    return {
        "course_label": course_label,
        "postgres_version": args.postgres_version,
        "pgadmin_enabled": not args.no_pgadmin,
        "pgadmin_user_role": args.pgadmin_user_role,
        "groups": groups,
        "users": users,
        "teacher": teacher,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--course-label", default="sql-2026-01")
    p.add_argument("--postgres-version", type=int, default=14)
    p.add_argument("--students", type=int, default=20)
    p.add_argument("--group-size", type=int, default=4)
    p.add_argument("--domain", default="dozilab.de")
    p.add_argument("--pgadmin-user-role", default="User", help="pgAdmin role name for non-admin users")
    p.add_argument("--no-teacher", action="store_true", help="Disable teacher account")
    p.add_argument("--no-pgadmin", action="store_true", help="Disable pgAdmin setup")
    args = p.parse_args()

    spec = build_spec(args)
    json_spec = json.dumps(spec, indent=2, sort_keys=True)
    b64 = base64.b64encode(json_spec.encode("utf-8")).decode("ascii")

    print("JSON spec:\n", json_spec)
    print("\nBase64 (paste into env.yaml 'course_spec_b64'):\n", b64)


if __name__ == "__main__":
    main()
