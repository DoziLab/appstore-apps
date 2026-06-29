# Ansible Docker Lab

Diese App stellt eine Ubuntu-VM mit Docker und Docker Compose bereit. Sie dient
als Uebungsumgebung fuer Container-Grundlagen und einfache Compose-Stacks.

## Zweck

Die App ergaenzt DoziLab um die Kategorie Container / DevOps. Studierende
koennen auf einer vorbereiteten VM Docker-Befehle ausprobieren und sehen direkt,
wie ein Compose-Projekt einen Webcontainer startet.

Typische Uebungen:

- Docker-Installation und Docker-Dienst pruefen
- laufende Container mit `docker ps` anzeigen
- Compose-Projekt starten, stoppen und Logs ansehen
- `docker-compose.yml` bearbeiten und erneut starten
- Unterschied zwischen Image, Container, Port-Mapping und Volume verstehen

## Architektur

- Heat erstellt VM, Root-Volume, Security Group und Floating IP.
- Das Backend verbindet sich per SSH mit der VM.
- Ansible installiert Docker und Docker Compose.
- Ansible erzeugt ein Demo-Projekt unter `/opt/dozilab/docker-lab`.
- Docker Compose startet einen Nginx-Container auf Port 80.

## Wichtige Dateien

- `app.yaml`: App-Metadaten, Parameter und Outputs
- `heat/main.yaml`: OpenStack-Infrastruktur
- `playbooks/main.yml`: Docker-, Compose- und Demo-Setup

## Testen

Nach dem Deployment den Output `demo_url` im Browser oeffnen.

Per SSH:

```bash
ssh -i ~/.ssh/heat-bastion-key.pem ubuntu@<floating-ip>
```

Auf der VM:

```bash
docker ps
cd /opt/dozilab/docker-lab
docker compose ps
docker compose logs
cat /var/lib/dozilab/ready
```

Falls die Distribution statt `docker compose` noch `docker-compose` verwendet,
kann der Bindestrich-Befehl genutzt werden:

```bash
docker-compose ps
```
