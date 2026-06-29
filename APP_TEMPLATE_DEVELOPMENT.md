# Entwicklung eines neuen DoziLab App-Templates

Diese Dokumentation richtet sich an App-Entwickler, die ein neues Template fuer
den DoziLab AppStore bauen wollen. Am besten liest man sie mit einem konkreten
Template neben dem Text. Als kleine Referenz-App dient
[`ansible_minimal_template_lab`](./ansible_minimal_template_lab). Fuer
vollstaendigere Apps sind [`ansible_multiuser`](./ansible_multiuser) und
[`ansible_postgres_group_db`](./ansible_postgres_group_db) nuetzlich.

## Grundidee

Ein App-Template ist ein Ordner im Repository `appstore-apps`. Der Ordner
enthaelt mindestens eine `app.yaml` und ein Heat-Template. Aktuelle Apps nutzen
zusaetzlich ein Ansible-Playbook. Heat erstellt die OpenStack-Ressourcen,
Ansible konfiguriert danach die VM ueber SSH.

Empfohlene Struktur:

```text
my_app/
+-- app.yaml
+-- README.md
+-- heat/
|   +-- main.yaml
+-- playbooks/
|   +-- main.yml
+-- files/
|   +-- ...
+-- scripts/
    +-- ...
```

`files/` und `scripts/` sind optional. Wenn sie benutzt werden, muessen sie in
`app.yaml` unter `artifacts` eingetragen werden. Das aktuelle Backend erkennt
einzelne Pfade und Listen von Pfaden. Siehe
[`ansible_minimal_template_lab/app.yaml`](./ansible_minimal_template_lab/app.yaml)
und [`ansible_multiuser/app.yaml`](./ansible_multiuser/app.yaml).

## `app.yaml`

`app.yaml` ist der Vertrag zwischen Template, Frontend und Backend. Die Datei
beschreibt, wie die App im AppStore angezeigt wird, welche Felder im
Deployment-Wizard erscheinen und welche Artefakte das Backend beim Deployment
verwenden soll.

Wichtige Abschnitte:

- `app`: Name, Label, Version, Beschreibung und Team. `app.name` sollte stabil
  bleiben, weil Deployments und Imports daran haengen.
- `artifacts`: Pfade zu Heat, Ansible, Skripten und Konfigurationsdateien.
- `parameters`: UI-Felder fuer den Wizard. Namen muessen zu den Heat-
  Parametern bzw. Playbook-Variablen passen.
- `credentials`: Backend-generierte Zugangsdaten fuer Gruppen und Teacher.
- `user_files`: Manifest-Metadaten fuer Datei-Uploads. Im aktuellen Backend-
  Deploymentpfad werden Uploads aber noch nicht nach `/opt/dozilab/user-files`
  kopiert.
- `outputs`: Werte, die aus Heat-Outputs in der Deployment-Ansicht angezeigt
  werden.

Beispiel fuer Artefakte:

```yaml
artifacts:
  heat_template: heat/main.yaml
  ansible_playbook: playbooks/main.yml
  shell_scripts:
    - scripts/check_template_setup.sh
  config_files:
    - files/welcome.txt
```

Ohne korrekte Artefakt-Zuordnung erkennt die Backend-Pipeline Dateien ggf. nur
als `OTHER`. Dann findet sie kein Heat-Template, kein Playbook oder kopiert
Hilfsdateien nicht nach `/opt/dozilab`. Fuer einzelne Dateien funktionieren
auch `shell_script: scripts/run.sh` und `config_file: files/config.txt`; fuer
mehrere Dateien sind `shell_scripts` und `config_files` als Listen vorgesehen.

## Parameter

Jeder Eintrag in `parameters` erzeugt ein Eingabefeld im Frontend und wird dem
Backend uebergeben. Parameter, die Heat braucht, muessen in
`heat/main.yaml` ebenfalls unter `parameters` definiert sein. Parameter, die nur
Ansible braucht, koennen direkt im Playbook genutzt werden.

Typische Felder:

- `stack_label`: kurzer technischer Name fuer Ressourcen und Metadaten.
- `image`: OpenStack-Image, als `enum` eingeschraenkt.
- `flavor`: OpenStack-Flavor, als `enum` eingeschraenkt.
- `volume_size`: Root-Disk-Groesse fuer Boot from Volume.
- `ssh_cidr`: CIDR, aus dem SSH erlaubt ist.
- `network` und `external_network`: meistens hidden und fest auf `NAT` bzw.
  `DHBW`.

Halte `app.yaml` und Heat-Constraints synchron. Wenn in `app.yaml` ein Image
waehlbar ist, muss es in `heat/main.yaml` ebenfalls erlaubt sein. Siehe
[`ansible_minimal_template_lab/heat/main.yaml`](./ansible_minimal_template_lab/heat/main.yaml).

OpenStack-Werte koennen so geprueft werden, wenn die OpenStack-Umgebung geladen
ist:

```bash
openstack image list -f value -c Name
openstack flavor list -f value -c Name
openstack network list -f value -c Name
openstack keypair list -f value -c Name
```

## Heat

Heat beschreibt die Infrastruktur. Fuer Ansible-Apps sollte Heat moeglichst nur
Ressourcen erstellen und keine groessere VM-Konfiguration per `user_data`
machen. Das aktuelle Muster ist:

- `OS::Neutron::SecurityGroup`
- `OS::Neutron::Port`
- `OS::Cinder::Volume` fuer Boot from Volume
- `OS::Nova::Server`
- `OS::Neutron::FloatingIP`
- `OS::Neutron::FloatingIPAssociation`
- `outputs` fuer IPs, URLs, Server-ID und Hinweise

`key_name` wird vom Backend gesetzt und muss im Heat-Template vorhanden sein.
In der UI wird der Key normalerweise nicht als sichtbarer Parameter angeboten.
Siehe [`ansible_postgres_group_db/heat/main.yaml`](./ansible_postgres_group_db/heat/main.yaml).

## Ansible

Das Playbook laeuft nach der Heat-Erstellung vom Backend aus ueber SSH. Bei den
Ubuntu-Images ist `remote_user: ubuntu` das gaengige Muster.

Das Backend stellt Variablen bereit, die das Playbook direkt verwenden kann:

- Parameter aus `app.yaml`, die nicht im Heat-Template definiert sind, z.B.
  `welcome_message`
- `stack_label`: wird im aktuellen Deployment-Task als tatsaechlicher
  Heat-Stack-Name an Ansible uebergeben
- `deployment_groups`: Gruppenliste fuer den aktuellen Stack
- `deployment_groups[].username`: backendseitig sanitizter Linux/User-Name
- `deployment_groups[].group_name`: Original-Gruppenname
- `deployment_groups[].linux.ssh_key.public_key`, wenn in `app.yaml`
  `ssh_key: generate` gesetzt ist
- `teacher`: Teacher-Kontext und Teacher-Credentials

Wichtig: Verwende nicht den Variablennamen `groups` fuer die Kursgruppenliste.
`groups` ist eine reservierte Ansible-Magic-Variable. Das Backend uebergibt
deshalb `deployment_groups`.
Siehe
[`ansible_minimal_template_lab/playbooks/main.yml`](./ansible_minimal_template_lab/playbooks/main.yml).

Empfohlen:

- Eingaben mit `assert` validieren.
- Secrets mit `no_log: true` schuetzen.
- idempotente Module wie `user`, `copy`, `file`, `apt`, `service` verwenden.
- optional einen Marker wie `/var/lib/dozilab/ready` fuer Debugging auf der VM
  schreiben. Das aktuelle Backend entscheidet den Deployment-Status fuer
  Ansible-Apps ueber den Erfolg von Heat und Ansible, nicht ueber diesen Marker.

## Credentials

Credentials werden in `app.yaml` deklariert und vom Backend erzeugt. Das
Playbook bekommt die fertigen Werte als Variablen.

Ein einfacher Linux-Account pro Gruppe:

```yaml
credentials:
  per_group:
    - linux:
        username: "{{ username }}"
        password: generate
        ssh_key: generate

  teacher:
    # teacher.linux automatisch vorhanden - kein Eintrag noetig.
```

Dann kann das Playbook z.B. auf `deployment_groups[].linux.password` und
`deployment_groups[].linux.ssh_key.public_key` zugreifen. Bei
`ssh_key: generate` erzeugt das Backend ein Ed25519-Keypair; der Public Key
wird in der VM installiert, der Private Key wird backendseitig gespeichert und
ueber die Student-/Credential-API ausgeliefert. Fuer komplexere Credentials
siehe PostgreSQL und pgAdmin in
[`ansible_postgres_group_db/app.yaml`](./ansible_postgres_group_db/app.yaml).

## User-Dateien

`user_files` kann im Manifest beschrieben werden und wird von der Template-
Version-API an das Frontend ausgeliefert. Im aktuellen Backend/Frontend ist der
vollstaendige Upload- und Copy-Pfad aber nicht implementiert. Dokumentiere
User-Dateien deshalb nur als geplantes/teilweise vorhandenes Feature oder
implementiere den Deployment-Pfad zuerst.

Das geplante Schema unterscheidet zwei Modi:

- `all_stacks`: eine Datei fuer alle Gruppen/Stacks
- `per_group`: unterschiedliche Dateien je Gruppe

Beispiel:

```yaml
user_files:
  - name: kursmaterial
    destination: /opt/dozilab/user-files/kursmaterial
    mode: all_stacks

  - name: gruppenmaterial
    destination: /opt/dozilab/user-files/{{ group_name }}/gruppenmaterial
    mode: per_group
```

Wenn der Upload-/Copy-Pfad implementiert ist, kann im Playbook z.B. mit
`user_files.kursmaterial.exists | default(false)` oder
`user_files.gruppenmaterial[item.group_name].exists | default(false)` geprueft,
ob eine Datei vorhanden ist.

## Outputs

Heat-Outputs werden in `app.yaml` sichtbar gemacht:

```yaml
outputs:
  - name: floating_ip
    label: Floating IP
    from_heat_output: floating_ip
```

Der Wert `from_heat_output` muss exakt einem Output in `heat/main.yaml`
entsprechen. Typische Outputs sind `floating_ip`, `private_ip`, `server_id`,
`ssh_hint`, `root_volume_id` oder app-spezifische URLs wie `pgadmin_url`.

## Tests vor dem Import

Mindestens diese Checks sollten lokal laufen:

```bash
ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path); puts "OK #{path}" }' \
  ansible_minimal_template_lab/app.yaml \
  ansible_minimal_template_lab/heat/main.yaml \
  ansible_minimal_template_lab/playbooks/main.yml
```

Wenn OpenStack-Zugang vorhanden ist:

```bash
openstack stack validate -t ansible_minimal_template_lab/heat/main.yaml
```

Fuer Playbooks:

```bash
ansible-playbook --syntax-check ansible_minimal_template_lab/playbooks/main.yml
```

Der vollstaendige Backend-Test ist ein Deployment ueber den DoziLab AppStore,
weil dabei Import, Parameter-Mapping, Credential-Erzeugung, Datei-Kopieren,
Heat und Ansible gemeinsam getestet werden.

## Praktischer Ablauf fuer eine neue App

1. `ansible_minimal_template_lab` kopieren und Ordner/App-Namen anpassen.
2. `app.yaml` zuerst bearbeiten: Metadaten, Parameter, Artefakte, Credentials
   und Outputs.
3. `heat/main.yaml` anpassen und Parameter/Constraints mit `app.yaml`
   synchron halten.
4. `playbooks/main.yml` schreiben und alle Backend-Variablen am Anfang
   validieren.
5. Zusaetzliche Dateien unter `files/` und `scripts/` ablegen und in
   `artifacts` eintragen.
6. YAML- und Ansible-Syntax pruefen.
7. App importieren und ein echtes Test-Deployment ausfuehren.

Wenn unklar ist, welches Muster verwendet werden soll: fuer Benutzer,
Passwoerter und SSH-Keys zuerst
[`ansible_minimal_template_lab`](./ansible_minimal_template_lab) lesen; fuer
mehrere Credential-Typen und service-spezifische Accounts zuerst
[`ansible_postgres_group_db`](./ansible_postgres_group_db) lesen.
