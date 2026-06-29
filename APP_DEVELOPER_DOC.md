# DoziLab App-Entwickler-Doku

Als Vorlage fuer neue Apps dient:

```text
appstore-apps/ansible_minimal_template_lab
```
Diese Dokumentation ist als Begleittext zur Template-App gedacht und sollte zusammen mit `appstore-apps/ansible_minimal_template_lab` gelesen werden. Die Template-App zeigt ein minimales, funktionierendes Beispiel. Die Dokumentation erklärt dazu, welche Stellen für eine eigene App typischerweise angepasst werden müssen.


## 1. Die wichtigsten Dateien

### `app.yaml`

`app.yaml` beschreibt die App fuer DoziLab.

Meistens anpassen:

- `app.name`: technischer Name, eindeutig und stabil.
- `app.label`: sichtbarer Name im UI.
- `app.version`: bei relevanten Aenderungen erhoehen.
- `app.description`: kurz beschreiben, was deployed wird.
- `parameters`: Felder im Deployment-Dialog.
- `credentials`: welche Zugangsdaten DoziLab erzeugen soll.
- `outputs`: welche Heat-Outputs im UI angezeigt werden.

Wenn die App Dateien aus `files/` oder `scripts/` nutzt, muessen diese unter
`artifacts` eingetragen sein. Sonst werden sie beim Deployment nicht als
App-Dateien verwendet.

### `heat/main.yaml`

Heat erstellt die OpenStack-Infrastruktur. App-Installation gehoert nicht hier
rein.

Meistens anpassen:

- `description`: auf die App anpassen.
- `parameters`: muss zu `app.yaml` passen.
- `secgroup.rules`: nur die Ports oeffnen, die die App braucht.
- `root_volume.properties.name`: passenden Volume-Namen setzen.
- `root_volume.properties.metadata.dozilab_app`: auf `app.name` setzen.
- `server.properties.name`: passenden VM-Namen setzen.
- `server.properties.metadata.dozilab_app`: auf `app.name` setzen.
- `outputs`: z.B. App-URL, Floating IP, Server ID.

Typische Ports:

- `22`: SSH
- `80`: HTTP
- `443`: HTTPS
- eigene App-Ports nur oeffnen, wenn sie wirklich von außen erreichbar sein
  sollen.

Wichtig: `key_name` muss als Heat-Parameter vorhanden bleiben. Das Backend setzt
diesen Wert automatisch.

### `playbooks/main.yml`

Ansible richtet die VM ein.

Meistens anpassen:

- `vars`: App-Name, Pfade, Service-Name.
- Validierungen: Welche Parameter und Credentials braucht die App?
- Verzeichnisse: Wo liegen Daten, Configs, Webroot oder Arbeitsordner?
- Pakete: Was muss installiert werden?
- Configs: Welche Dateien muessen geschrieben oder kopiert werden?
- Benutzer/Rechte: Wer darf was lesen oder schreiben?
- Service: systemd, Docker Compose, Nginx, Datenbank oder anderer Dienst.
- Checks: `systemctl`, `docker ps`, HTTP-Check oder App-spezifische CLI.
- Ready-Marker: Inhalt von `/var/lib/dozilab/ready`.

Das Backend uebergibt unter anderem:

- `teacher`
- `deployment_groups`
- Parameter aus `app.yaml`
- generierte Credentials

Nicht `groups` als eigene Variable verwenden. Das ist bei Ansible reserviert.
DoziLab nutzt deshalb `deployment_groups`.

## 2. Credentials

Ein Gruppen-Linux-Account:

```yaml
credentials:
  per_group:
    - linux:
        username: "{{ username }}"
        password: generate
        ssh_key: generate
```

Im Playbook nutzt man dann:

```text
deployment_groups[].linux.username
deployment_groups[].linux.password
deployment_groups[].linux.ssh_key.public_key
```

`teacher.linux` wird automatisch erzeugt.

Bei Passwort-, Token- oder Link-Tasks immer setzen:

```yaml
no_log: true
```

## 3. Merksatz

- `app.yaml`: Was sieht DoziLab?
- `heat/main.yaml`: Welche Infrastruktur wird gebaut?
- `playbooks/main.yml`: Was passiert auf der VM?

## Zur Vollstaendigkeit halber

Dieser Teil ist nicht zwingend fuer eine einfache App. Er ist als Ideensammlung
gedacht, wenn eine App mehr kann als die Minimalvorlage.

### Parameter

Parameter aus `app.yaml` landen entweder in Heat oder in Ansible:

- Wenn der Name auch in `heat/main.yaml` unter `parameters` steht, nutzt Heat
  den Wert.
- Wenn Heat den Parameter nicht kennt, kann das Playbook ihn als Ansible-Variable
  verwenden.

Typische Parameter:

- `stack_label`: kurzer Name fuer Ressourcen.
- `image`: Ubuntu-Image.
- `flavor`: VM-Groesse.
- `volume_size`: Root-Disk-Groesse.
- `ssh_cidr`: erlaubtes Netz fuer SSH.
- `web_cidr`: erlaubtes Netz fuer HTTP/HTTPS.
- `network`: meistens hidden, z.B. `NAT`.
- `external_network`: meistens hidden, z.B. `DHBW`.

### Outputs

Ein Output muss in Heat existieren und in `app.yaml` referenziert werden.

In Heat:

```yaml
outputs:
  app_url:
    value:
      str_replace:
        template: "http://FIP/"
        params:
          FIP: { get_attr: [fip, floating_ip_address] }
```

In `app.yaml`:

```yaml
outputs:
  - name: app_url
    label: App URL
    from_heat_output: app_url
```

### Dateien aus `files/` und `scripts/`

Alles, was das Playbook auf der VM braucht, muss in `app.yaml` unter
`artifacts` stehen.

```yaml
artifacts:
  heat_template: heat/main.yaml
  ansible_playbook: playbooks/main.yml
  shell_scripts:
    - scripts/check_setup.sh
  config_files:
    - files/example.conf
```

Das Backend kopiert diese Dateien nach `/opt/dozilab/scripts` bzw.
`/opt/dozilab/files`.

### User-Files

`user_files` nur nutzen, wenn Lehrende beim Deployment Dateien hochladen sollen.

Typische Modi:

- `all_stacks`: gleiche Datei fuer alle Gruppen.
- `per_group`: eigene Datei pro Gruppe.

Im Playbook sollte immer geprueft werden, ob die Datei existiert:

```yaml
when: (user_files.material | default({})).exists | default(false)
```

### Rechte

Vor dem Schreiben des Playbooks klaeren:

- Muss jede Gruppe nur eigene Dateien sehen?
- Darf der Webserver nur lesen oder auch schreiben?
- Brauchen Gruppen sudo-Rechte?
- Ist Docker-Zugriff erlaubt? Docker ist praktisch root-nah.

Bei sensiblen Dateien:

- `/etc/dozilab`: eher `0700`
- Secret-Dateien: eher `0600`
- Webroot je nach App: oft eigener User oder eigene Gruppe

### Services

Moegliche Muster:

- systemd Unit fuer einfache Prozesse.
- Nginx/Apache fuer statische Seiten oder Reverse Proxy.
- Docker Compose fuer Container-Apps.
- App-eigene CLI fuer Benutzeranlage oder Initialisierung.

Nach dem Start immer pruefen, ob der Dienst wirklich laeuft.

### Re-Deploys

Playbooks sollten moeglichst idempotent sein:

- `file`, `copy`, `user`, `apt`, `service` bevorzugen.
- `shell` und `command` nur verwenden, wenn es noetig ist.
- Bei `command`/`shell` `changed_when` sinnvoll setzen.

### Aktivierungslinks

Overleaf ist ein Sonderfall: Dort gibt es keine festen Passwoerter, sondern
Aktivierungslinks. Die App schreibt dafuer eine JSON-Datei auf die VM, die das
Backend nach Ansible ausliest.

Interessant bei solchen Apps:

- Links sauber aus CLI-Ausgaben extrahieren.
- Keine `\n` oder `\r` am Ende des Links.
- Links als Secret behandeln.

### Beispiele im Repository

- `ansible_docker_lab`: Docker installieren, Docker-Gruppe, Demo-Container.
- `ansible_multiuser`: viele Linux-User, Passwortregeln, SSH-Keys.
- `ansible_static_website_lab`: getrennte Webroots und Rechte pro Gruppe.
- `ansible_postgres_group_db`: Datenbank- und pgAdmin-Credentials.
- `ansible_overleaf_latex_lab`: Aktivierungslinks nach dem Deployment.
- `ansible_openproject_lab`: App-User nach Containerstart anlegen.
