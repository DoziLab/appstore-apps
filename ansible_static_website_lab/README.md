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
- Dateien unter `/var/www/html` ohne sudo bearbeiten
- Nginx-Konfiguration ansehen
- Deployment-Ablauf Heat plus Ansible nachvollziehen

## Architektur

- Heat erstellt VM, Root-Volume, Security Group und Floating IP.
- Das Backend verbindet sich per SSH mit der VM.
- Ansible installiert Nginx und schreibt eine Beispielseite.
- Ansible erzeugt pro Kursgruppe einen Linux-Login und nimmt ihn in die
  Gruppe `webedit` auf.
- `/var/www/html` ist fuer `webedit` schreibbar. Nginx liefert die Dateien
  direkt aus; nach dem Speichern reicht ein Browser-Refresh.
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
ssh <gruppen-user>@<floating-ip>
```

Auf der VM:

```bash
curl -I http://127.0.0.1/
nano /var/www/html/index.html
ls -la /var/www/html
cat /var/lib/dozilab/ready
```
