# Ansible OpenProject Lab

Diese App stellt eine Ubuntu-VM mit OpenProject bereit. Sie ist fuer
Projektmanagement-Uebungen gedacht, zum Beispiel fuer Aufgabenplanung,
Gantt-Ansichten, Statusverfolgung, Rollenverteilung und Teamarbeit.

## Zweck

Die App ergaenzt die bisherigen DoziLab-Apps um die Kategorie
Projektmanagement / Software Engineering. Sie ist sinnvoll fuer Kurse, in denen
Projektstruktur, Meilensteine, Arbeitspakete, Zeitplanung oder agile Boards
praktisch gezeigt werden sollen.

Typische Uebungen:

- Projekt und Arbeitspakete anlegen
- Verantwortlichkeiten und Status pflegen
- Gantt-Ansicht fuer Terminplanung nutzen
- Boards und Aufgabenlisten vergleichen
- Projektfortschritt im Team besprechen

## Architektur

- Heat erstellt VM, Root-Volume, Security Group und Floating IP.
- Das Backend verbindet sich per SSH mit der VM.
- Ansible installiert Docker und startet OpenProject als Container.
- OpenProject ist ueber HTTP Port 80 erreichbar.
- Daten liegen unter `/var/lib/openproject`.

## Wichtige Dateien

- `app.yaml`: App-Metadaten, Parameter und Outputs
- `heat/main.yaml`: OpenStack-Infrastruktur
- `playbooks/main.yml`: Docker- und OpenProject-Setup

## Login

DoziLab erzeugt beim Deployment OpenProject-Logins:

- `admin` fuer den Dozenten/Administrator
- ein Login pro Kursgruppe

Die OpenProject-Logins verwenden dieselben generierten DoziLab-Credentials, die
in den Deployment-Credentials angezeigt werden. Der OpenProject-Default
`admin / admin` wird nach dem ersten Start durch das generierte Admin-Passwort
ersetzt.

## Testen

Nach dem Deployment den Output `openproject_url` im Browser oeffnen.

Per SSH:

```bash
ssh -i ~/.ssh/heat-bastion-key.pem ubuntu@<floating-ip>
```

Auf der VM:

```bash
sudo systemctl status openproject --no-pager
sudo docker ps
cat /var/lib/dozilab/ready
```
