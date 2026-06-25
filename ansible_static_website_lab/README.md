# Ansible Static Website Lab

Diese App stellt eine kleine Ubuntu-VM mit Nginx bereit. Sie dient als
Webhosting-Lab fuer einfache HTML-, CSS- und JavaScript-Uebungen.

## Zweck

Die App ergaenzt die bisherigen DoziLab-Apps um eine einfache Webhosting-
Kategorie. Dozenten koennen damit zeigen, wie statische Webseiten auf einem
Linux-Server ausgeliefert werden und wo Dateien auf einem Webserver liegen.

Typische Uebungen:

- Website ueber HTTP im Browser aufrufen
- per SSH auf die VM gehen
- Dateien unter `/var/www/html` bearbeiten
- Nginx-Konfiguration ansehen
- Deployment-Ablauf Heat plus Ansible nachvollziehen

## Architektur

- Heat erstellt VM, Root-Volume, Security Group und Floating IP.
- Das Backend verbindet sich per SSH mit der VM.
- Ansible installiert Nginx und schreibt eine Beispielseite.
- HTTP Port 80 ist nur aus dem konfigurierten `web_cidr` erreichbar.
- SSH Port 22 ist nur aus dem konfigurierten `ssh_cidr` erreichbar.

## Wichtige Dateien

- `app.yaml`: App-Metadaten, Parameter und Outputs
- `heat/main.yaml`: OpenStack-Infrastruktur
- `playbooks/main.yml`: Installation und Konfiguration von Nginx

## Testen

Nach dem Deployment den Output `website_url` im Browser oeffnen.

Per SSH:

```bash
ssh -i ~/.ssh/heat-bastion-key.pem ubuntu@<floating-ip>
```

Auf der VM:

```bash
curl -I http://127.0.0.1/
sudo systemctl status nginx --no-pager
cat /var/lib/dozilab/ready
```
