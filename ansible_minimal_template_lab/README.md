# DoziLab Ansible Minimal Template Lab

Diese App ist eine kleine, backend-kompatible Beispiel-App fuer neue DoziLab
Templates. Sie ist bewusst einfacher als produktive Apps, zeigt aber die
wichtigsten Bausteine:

- `app.yaml` fuer AppStore-Metadaten, UI-Parameter, Artefakte, Credentials
  und Outputs
- `heat/main.yaml` fuer OpenStack-Infrastruktur
- `playbooks/main.yml` fuer die Konfiguration per Ansible
- `files/` und `scripts/` als zusaetzliche Artefakte, die das Backend vor dem
  Playbook auf die VM kopiert

## Struktur

```text
ansible_minimal_template_lab/
+-- app.yaml
+-- README.md
+-- files/
|   +-- welcome.txt
+-- heat/
|   +-- main.yaml
+-- playbooks/
|   +-- main.yml
+-- scripts/
    +-- check_template_setup.sh
```

## Verhalten

Heat erstellt eine Ubuntu-VM mit Cinder Root-Volume, Security Group, Port und
Floating IP. Danach fuehrt das Backend das Ansible-Playbook aus.

Das Playbook legt pro Kursgruppe einen Linux-User an, setzt das vom Backend
generierte Passwort, installiert optional den generierten SSH Public Key und
schreibt eine Welcome-Datei in das Home-Verzeichnis. Am Ende schreibt es
`/var/lib/dozilab/ready` als VM-internen Debug-Marker.

## Backend-Variablen

Die App erwartet die Variablen, die das aktuelle Backend an Ansible uebergibt:

- `deployment_groups[].username`
- `deployment_groups[].group_name`
- `deployment_groups[].linux.password`
- `deployment_groups[].linux.ssh_key.public_key`, wenn `ssh_key: generate`
  in `app.yaml` gesetzt ist
- `teacher`, automatisch durch das Backend bereitgestellt

## Referenzen

Diese App ist die kleinste Lesereferenz. Fuer produktivere Muster siehe:

- [`../ansible_multiuser`](../ansible_multiuser)
- [`../ansible_postgres_group_db`](../ansible_postgres_group_db)
- [`../APP_TEMPLATE_DEVELOPMENT.md`](../APP_TEMPLATE_DEVELOPMENT.md)
