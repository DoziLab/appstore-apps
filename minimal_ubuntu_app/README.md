# DoziLab Minimal Ubuntu Beispiel-App

Diese App dient als einfache Vorlage fuer Dozenten und App-Entwickler, die eigene
Apps fuer den DoziLab AppStore bauen, hochladen oder releasen wollen.

Sie macht bewusst nur das Minimum:

- eine Ubuntu-VM starten
- SSH ueber eine Security Group erlauben
- eine Floating IP zuweisen
- ein kleines cloud-init Skript ausfuehren
- einen READY- oder FAILED-Marker schreiben
- wichtige Outputs zurueckgeben

## Struktur

```text
minimal_ubuntu_app/
├── app.yaml
├── env.yaml
├── heat/
│   └── main.yaml
└── cloud-init/
    └── user-data.yaml
```

## Wofuer die Dateien da sind

- `app.yaml`: Metadaten, UI-Parameter und Outputs fuer den AppStore
- `heat/main.yaml`: OpenStack-Ressourcen wie VM, Port, Security Group und Floating IP
- `cloud-init/user-data.yaml`: Skript, das beim ersten Start in der VM laeuft
- `env.yaml`: Beispielwerte fuer lokale Tests mit der OpenStack CLI

## Eigene App daraus bauen

1. Ordner kopieren und Namen anpassen.
2. `app.yaml` anpassen: App-Name, Label, Beschreibung, Parameter, Outputs.
3. `heat/main.yaml` erweitern: benoetigte OpenStack-Ressourcen eintragen.
4. `cloud-init/user-data.yaml` erweitern: Software installieren und konfigurieren.
5. READY/FAILED-Marker beibehalten, damit der Deployment-Status auswertbar bleibt.

## Testen

```bash
openstack stack validate \
  -t heat/main.yaml \
  -e env.yaml
```

```bash
openstack stack create \
  -t heat/main.yaml \
  -e env.yaml \
  minimal-test
```

## Outputs

- `floating_ip`
- `private_ip`
- `ssh_user`
- `server_id`
- `ssh_hint`
- `ready_marker`
