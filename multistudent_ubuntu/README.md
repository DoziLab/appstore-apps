# DoziLab Multi-Student Ubuntu VM (V1)

Diese App deployt **eine Ubuntu-VM** für Lehrveranstaltungen mit mehreren lokalen
Studenten-Accounts (Username/Passwort), kontrolliertem SSH-Zugriff und klarer
Backend-Orchestrierung über Heat.

---

## Überblick

Die App erstellt automatisiert:

- **1 Ubuntu VM**
- **mehrere lokale Benutzerkonten** (Studenten) mit Passwort-Login
- **SSH-Zugriff nur aus definiertem CIDR** (Standard: DHBW/VPN)
- **Floating IP** aus dem DHBW-Netz
- **READY-Marker** im Nova Console Log für Backend-Polling (Nach was muss das Backend Ausschau halten um zu wissen wann die VM ready ist)

Ziel ist eine **robuste, einfache V1**, ohne unnötige Konfigurationsfreiheit,
aber mit sauberer Erweiterbarkeit.

---

## Verzeichnisstruktur

```
multistudent_ubuntu/
├── app.yaml
├── env.yaml
├── heat/
│   └── main.yaml
└── cloud-init/
    └── user-data.yaml
```

---

## Design-Entscheidungen (warum das so gebaut ist)

### Feste Netzwerke (NAT + DHBW)
- `network` ist fest auf **NAT** gesetzt
- `external_network` ist fest auf **DHBW**

Begründung:
- Studierenden-VMs brauchen **kein freies Routing**
- Floating IPs kommen ausschließlich aus dem Campus-Netz
- Weniger Fehlerquellen, weniger UI-Komplexität

---

### SSH-Zugriff über CIDR

Standard:
```
ssh_cidr = 141.72.0.0/16
```

Begründung:
- Zugriff nur aus DHBW/VPN möglich
- Auch bei öffentlicher Floating IP keine externe Erreichbarkeit
- CIDR bleibt konfigurierbar für Sonderfälle (z.B. andere VPN-Ranges)

---

### SSH-Keys

- Es wird **immer genau ein SSH-Key** gesetzt (`heat-bastion-key`)
- Dieser Key gehört dem **Admin / Support**
- Studenten nutzen **ausschließlich Passwort-Login**

Begründung:
- Kein Key-Management im Frontend nötig
- Support-Zugriff jederzeit möglich
- Klare Trennung zwischen Admin und Studierenden

---

### Studenten-Accounts

Parameter (`user_json`, unencoded Beispiel):
```json
{
  "course_label": "ubuntumulti",
  "instance": {
    "credentials": [
      { "username": "gruppe01", "password": "User01_2026!" },
      { "username": "gruppe02", "password": "User02_2026!!" }
    ],
    "admin_credentials": {
      "username": "teacher",
      "password": "TeacherPw_2026!"
    }
  },
  "applications": []
}
```

Eigenschaften:
- Lokale Linux-User
- Passwort wird beim ersten Login gesetzt
- Optionaler Passwort-Zwang beim ersten Login (`force_password_change`)

Begründung:
- Passt zu Lehrveranstaltungen
- Einfach verständlich
- Kein LDAP / Keycloak / externe Abhängigkeiten in V1

Hinweis:
- Backend sendet den Heat-Parameter `user_json` als **Base64-kodierten JSON-String** (bevorzugt).
- Raw-JSON (multi-line) wird ebenfalls akzeptiert, z.B. für lokale Tests.

---

### Passwort-Policy (pwquality)

Die Passwortregeln sind **explizit steuerbar**:

- Mindestlänge
- Ziffernpflicht
- Großbuchstabenpflicht
- Sonderzeichenpflicht

Wichtig:
- Es wird **nur** das enforced, was auch im UI sichtbar ist
- Keine versteckten PAM-Regeln

---

### READY-Marker

Am Ende des cloud-init-Prozesses wird geschrieben:

```
DOZILAB_READY stack=<label> time=<timestamp>
```

Ort:
- Nova Console Log
- Zusätzlich Datei: `/var/lib/dozilab/ready`

Begründung:
- Backend kann zuverlässig pollen
- Kein SSH / kein Agent notwendig
- Robust gegenüber Reboots

---

## Stack-Erstellung (CLI)

```bash
openstack stack create \
  -t heat/main.yaml \
  -e env.yaml \
  dozilab-kurs-01
```

Stack validieren:
```bash
openstack stack validate -t heat/main.yaml -e env.yaml
```

Outputs abrufen:
```bash
openstack stack output show dozilab-kurs-01 floating_ip -f value -c output_value
```

---

## Erweiterungen (nicht Teil von V1)

Bewusst **nicht** umgesetzt in der ersten Version:

- Mehrere VMs pro Stack (ResourceGroup)
- SSH-Key-Auswahl für Dozenten
- HTTP/HTTPS-Services
- LDAP / Keycloak Integration
- UI-Validierung der Studentenliste

Diese Punkte sind **bewusst verschoben**, um eine stabile Basis zu haben.

---

## Status

**V1: produktionsfähig für Lehrbetrieb**  
Getestet mit:
- Ubuntu 22.04 / 24.04
- OpenStack (Heat + Neutron + Nova)
- Mehreren Studenten-Accounts
