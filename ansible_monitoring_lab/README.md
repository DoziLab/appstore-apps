# Ansible Monitoring Lab

Diese App stellt eine Ubuntu-VM mit Grafana, Prometheus und Node Exporter bereit.
Sie dient als Uebungsumgebung fuer Monitoring- und Observability-Grundlagen.

## Zweck

Die App ergaenzt DoziLab um die Kategorie Betrieb / Monitoring / DevOps.
Studierende koennen damit sehen, wie Systemmetriken gesammelt, gespeichert und in
Dashboards visualisiert werden.

Typische Uebungen:

- Grafana-Dashboard im Browser oeffnen
- CPU-, RAM-, Disk- und Netzwerkmetriken interpretieren
- Prometheus-Targets und Scrape-Konfiguration nachvollziehen
- einfache PromQL-Abfragen ausprobieren
- Zusammenhang zwischen Exporter, Prometheus und Grafana verstehen

## Architektur

- Heat erstellt VM, Root-Volume, Security Group und Floating IP.
- Das Backend verbindet sich per SSH mit der VM.
- Ansible installiert Docker und Docker Compose.
- Docker Compose startet Grafana, Prometheus und Node Exporter.
- Grafana ist ueber HTTP Port 80 erreichbar.
- Prometheus und Node Exporter sind nur intern im Compose-Netz erreichbar.
- Pro Kursgruppe wird eine eigene Grafana-Organization mit eigenem Login
  angelegt. Gruppen sehen und bearbeiten dadurch nur ihren eigenen
  Grafana-Arbeitsbereich.

## Login

DoziLab erzeugt beim Deployment Logins:

- `admin` fuer den Dozenten/Administrator
- ein Login pro Kursgruppe

Die Grafana-Logins verwenden dieselben generierten DoziLab-Credentials, die in
den Deployment-Credentials angezeigt werden. Anonymer Grafana-Zugriff ist
deaktiviert.

## Wichtige Dateien

- `app.yaml`: App-Metadaten, Parameter und Outputs
- `heat/main.yaml`: OpenStack-Infrastruktur
- `playbooks/main.yml`: Docker-, Prometheus- und Grafana-Setup

## Testen

Nach dem Deployment den Output `grafana_url` im Browser oeffnen.

Per SSH:

```bash
ssh -i ~/.ssh/heat-bastion-key.pem ubuntu@<floating-ip>
```

Auf der VM:

```bash
docker ps
cd /opt/dozilab/monitoring-lab
docker compose ps
docker compose logs grafana
cat /var/lib/dozilab/ready
```
