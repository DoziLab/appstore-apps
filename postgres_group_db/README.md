# DoziLab PostgreSQL Group DB

Diese App provisioniert **eine Ubuntu-VM pro Kurs/Stack** mit PostgreSQL (nur localhost)
und optional pgAdmin im Web. Sie richtet **Gruppen-DBs** ein, legt **Studenten-Accounts**
an und vergibt **saubere Rechte pro Gruppe**.

## Überblick

Die App erstellt:

- 1 Ubuntu VM
- Root-Disk als Cinder-Volume (Boot from Volume), Speicher groesse konfigurierbar
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
- `volume_size` (number, required)
  - Root-Disk als Cinder-Volume in GB (z.B. `8`, `16`, `32`)
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
- `user_json` (string, required)
  - Base64-kodiertes JSON (eine Zeile, keine Newlines) ODER Raw-JSON (multi-line)
  - Legacy: base64-kodiertes Python-Literal wird akzeptiert

**Wichtig:** Bevorzugt **UTF-8 JSON** als Base64 ohne Zeilenumbrueche.

---

## user_json JSON (Schema)

Beispiel (unencoded):
```json
{
  "course_label": "SQL Kurs - Herbst 2026",
  "instance": {},
  "postgres_version": 14,
  "applications": [
    {
      "name": "postgres",
      "version": "1.3.2",
      "credentials": [
        {
          "group": 1,
          "database_name": "db_g01",
          "db_user": "grp1",
          "password": "Grp1DbPw_2026!"
        }
      ],
      "admin_credentials": {
        "db_user": "teacher",
        "password": "TeacherDbPw_2026!"
      }
    },
    {
      "name": "pgadmin",
      "version": "4.3.2",
      "credentials": [
        {
          "group": 1,
          "email": "grp1@dozi.edu",
          "password": "Grp1PgPw_2026!"
        }
      ],
      "admin_credentials": {
        "email": "teacher@dozi.edu",
        "password": "TeacherPgPw_2026!"
      }
    }
  ]
}
```

### Felder
- `course_label` (string, optional)
- `instance` (object, optional; aktuell ignoriert)
- `postgres_version` (int, optional; 10..17). Auch als `postgresVersion` akzeptiert; alternativ im Postgres-App-Objekt via `postgres_version`/`postgresVersion`.
- `applications` (array, required); enthaelt mindestens `name: "postgres"` (oder `"postgresql"`). Optional `name: "pgadmin"`.
- Postgres-App: `credentials` (list) mit `group`, `database_name` (oder `db_name`), `db_user`, `password`; `admin_credentials` optional (`db_user`, `password`).
- pgAdmin-App (optional): `credentials` (list) mit `group`, `email`, `password`; `admin_credentials` required (`email`, `password`).

### Validierung/Constraints
- `group` token: `[A-Za-z0-9_]`, 1..32 (string oder Zahl)
- `database_name`/`db_name` und `db_user` muessen dem Regex folgen: `^[a-z_][a-z0-9_]{0,62}$`
- Passwortlaenge min. 6
- `db_user` muss eindeutig sein; pgAdmin-E-Mails muessen eindeutig sein
- Wenn `pgadmin` vorhanden ist, muessen `credentials` und `admin_credentials` gesetzt sein

### Generator (Legacy)
Der Generator `base64_erzeuger.py` erzeugt das alte `course_spec`-Format und ist nicht mehr kompatibel. Wenn ihr einen Generator fuer `user_json` braucht, sag Bescheid.

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
Login mit `email`/`password` aus `user_json` (`pgadmin.admin_credentials` fuer Admins oder `pgadmin.credentials` fuer User).

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
- `root_volume_id` (Cinder Root-Volume)

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
