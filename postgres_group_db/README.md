# DoziLab PostgreSQL Group DB

Diese App provisioniert **eine Ubuntu-VM pro Kurs/Stack** mit PostgreSQL (nur localhost)
und optional pgAdmin im Web. Sie richtet **Gruppen-DBs** ein, legt **Studenten-Accounts**
an und vergibt **saubere Rechte pro Gruppe**.

## Überblick

Die App erstellt:

- 1 Ubuntu VM
- PostgreSQL (Standard: Version 14, nur `127.0.0.1`)
- pro Gruppe eine Datenbank
- pro Student einen Postgres-Login
- eine Gruppenrolle `grp_<gid>` pro Gruppe
- optional pgAdmin4 Web-UI inkl. pgAdmin-Accounts

**Sicherheit/Isolation**

- Zugriff auf Postgres nur per SSH-Tunnel oder lokal auf der VM
- Jede Gruppe hat **nur Zugriff auf ihre eigene DB**
- PUBLIC-Rechte sind entfernt
- Innerhalb der Gruppe werden Objekte standardmaessig geteilt

---

## Dateien

```
postgres_group_db/
├── app.yaml
├── env.yaml
├── heat/
│   └── main.yaml
└── cloud-init/
    └── user-data.yaml
```

---

## Backend-Parameter (exakt)

Die App erwartet die folgenden Heat-Parameter **mit diesen Namen**:

### Stack/VM
- `stack_label` (string, required)
  - Kurzlabel fuer Namen/Marker (z.B. `sql-2026-01`)
- `image` (string, required)
  - z.B. `"Ubuntu 22.04 2025-01"`
- `flavor` (string, required)
  - z.B. `"gp1.small"`
- `network` (string, fixed)
  - `"NAT"`
- `external_network` (string, fixed)
  - `"DHBW"`
- `key_name` (string, fixed)
  - `"heat-bastion-key"`

### Zugriff
- `ssh_cidr` (string, required)
  - CIDR fuer SSH, z.B. `"141.72.0.0/16"`
- `web_cidr` (string, required)
  - CIDR fuer pgAdmin HTTP (Port 80)

### Kurs-Spezifikation
- `course_spec_b64` (string, required)
  - Base64-kodiertes JSON (eine Zeile, keine Newlines)

**Wichtig:** `course_spec_b64` muss **UTF-8 JSON** sein, Base64-kodiert und ohne Zeilenumbrueche.

---

## course_spec JSON (Schema)

Beispiel (unencoded):
```json
{
  "course_label": "sql-2026-01",
  "postgres_version": 14,
  "pgadmin_enabled": true,
  "pgadmin_user_role": "User",
  "groups": {
    "g01": {"db_name": "sql_2026_01_g01"},
    "g02": {"db_name": "sql_2026_01_g02"}
  },
  "users": {
    "s01": {
      "group": "g01",
      "db_user": "s01",
      "db_password": "DbPw-s01-ChangeMe!",
      "pgadmin_email": "s01@dozi.edu",
      "pgadmin_password": "PgPw-s01-ChangeMe!"
    }
  },
  "teacher": {
    "enabled": true,
    "db_user": "teacher",
    "db_password": "TeacherDbPw-ChangeMe!",
    "pgadmin_email": "teacher@dozi.edu",
    "pgadmin_password": "TeacherPgPw-ChangeMe!"
  }
}
```

### Felder
- `course_label` (string)
- `postgres_version` (int, 10..17)
- `pgadmin_enabled` (bool)
- `pgadmin_user_role` (string)
  - Rolle fuer alle Nicht-Admins in pgAdmin (bei pgAdmin 4: `"User"`)
- `groups` (object, required)
  - Key: Gruppen-ID (z.B. `g01`)
  - Value: `{ "db_name": "<db_name>" }`
- `users` (object, optional)
  - Key: User-ID (z.B. `s01`)
  - Value:
    - `group` (string, required) -> muss in `groups` existieren
    - `db_user` (string, optional; default = Key)
    - `db_password` (string, required; min 6)
    - `pgadmin_email` (string, optional)
    - `pgadmin_password` (string, optional)
- `teacher` (object, optional)
  - `enabled` (bool)
  - `db_user` (string; default `teacher`)
  - `db_password` (string; min 6)
  - `pgadmin_email` / `pgadmin_password`

### Validierung/Constraints
- `db_name` und `db_user` muessen dem Regex folgen:
  - `^[a-z_][a-z0-9_]{0,62}$`
- `users[*].group` muss existieren
- Passwortlaenge min. 6

### Generator
Im Repo gibt es einen Generator:
```
python3 base64_erzeuger.py --students 20 --group-size 4 --domain dozi.edu
```
Der Output enthaelt das JSON und die passende Base64-Zeile fuer `course_spec_b64`.

---

## Rechte-Setup (Kurz)

- Jede Gruppe erhaelt eine Rolle `grp_<gid>`
- Datenbank-Owner = Gruppenrolle
- PUBLIC-Rechte auf DB/Schema entfernt
- Gruppe erhaelt CONNECT/CREATE/USAGE in ihrer DB
- Default-Privileges teilen neue Tabellen/Sequenzen innerhalb der Gruppe
- Teacher bekommt alle Gruppenrollen

---

## Zugriff

### SSH (Admin)
```
ssh -i ~/.ssh/heat-bastion-key.pem ubuntu@<floating_ip>
```

### Postgres via SSH-Tunnel
```
ssh -i ~/.ssh/heat-bastion-key.pem -L 5432:127.0.0.1:5432 ubuntu@<floating_ip>
```

### pgAdmin Web
```
http://<floating_ip>/pgadmin4/
```
Login mit `pgadmin_email`/`pgadmin_password` aus `course_spec`.

---

## Outputs (Heat)

- `floating_ip`
- `private_ip`
- `ssh_user` (immer `ubuntu`)
- `server_id`
- `pgadmin_url`
- `ssh_hint`
- `ssh_tunnel_hint`
- `ready_marker` (in Nova Console Log)

---

## Ready/Fail Marker

Bei Erfolg:
```
DOZILAB_READY stack=<label> time=<timestamp>
```
Datei: `/var/lib/dozilab/ready`

Bei Fehler:
```
DOZILAB_FAILED stack=<label> rc=<code> time=<timestamp>
```
Datei: `/var/lib/dozilab/failed`
