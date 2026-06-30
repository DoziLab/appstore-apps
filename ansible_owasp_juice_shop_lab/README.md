# DoziLab OWASP Juice Shop Lab

Diese App stellt isolierte OWASP Juice Shop Instanzen fuer Web-Security- und
Pentesting-Grundlagen bereit. Jede Kursgruppe bekommt einen eigenen Container
mit eigener Basic-Auth vor der Weboberflaeche. Sie ist als Trainingsziel fuer eigene
Lehrveranstaltungen gedacht.

Wichtig: Die App ist bewusst verwundbar. Sie soll nur in der bereitgestellten
Lab-VM und nur im erlaubten Kurs-/Campusnetz verwendet werden. Sie ist nicht als
allgemeine Angriffsumgebung fuer fremde Ziele gedacht.

## Ueberblick

Die App erstellt:

- eine Ubuntu-VM
- Docker
- pro Kursgruppe einen eigenen OWASP Juice Shop Container
- Nginx als Uebersichtsseite auf Port 80
- Nginx Basic Auth vor jeder Gruppeninstanz
- SSH-Zugriff nur aus `ssh_cidr`
- Webzugriff nur aus `web_cidr` auf Port 80 und die Gruppenports 30000-30099
- READY/FAILED-Marker unter `/var/lib/dozilab`
- Backend-Credentials pro Gruppe unter `deployment_groups[].juice_shop`

Die VM bootet von einem Cinder Root-Volume.

## Struktur

```text
ansible_owasp_juice_shop_lab/
├── app.yaml
├── heat/
│   └── main.yaml
└── playbooks/
    └── main.yml
```

## Zugriff

Uebersicht:

```text
http://<floating_ip>/
```

Die Uebersicht verlinkt die Gruppeninstanzen auf eigenen Ports:

```text
http://<floating_ip>:30000/
http://<floating_ip>:30001/
...
```

Jede Gruppeninstanz ist per Basic Auth geschuetzt. Die Zugangsdaten kommen aus
dem Backend-Credential-System:

- Gruppe: `deployment_groups[].juice_shop.username/password`
- Teacher: `teacher.juice_shop.username/password`

Der Teacher-Zugang wird in jede Gruppeninstanz als zusaetzlicher Basic-Auth-
Benutzer eingetragen.

Admin-SSH:

```bash
ssh -i ~/.ssh/heat-bastion-key.pem ubuntu@<floating_ip>
```

## Testen

```bash
openstack stack create \
  -t heat/main.yaml \
  -e env.yaml \
  juice-test
```

Status pruefen:

```bash
openstack stack show juice-test
```

URL holen:

```bash
openstack stack output show juice-test web_url -f value -c output_value
```

READY-Marker pruefen:

```bash
SERVER_ID=$(openstack stack output show juice-test server_id -f value -c output_value)
openstack console log show "$SERVER_ID" | grep DOZILAB
```

## Hinweise fuer den Unterricht

- Die App stellt ein Zielsystem bereit, an dem Web-Security-Konzepte geuebt
  werden koennen.
- Gruppen arbeiten getrennt, weil jede Gruppe einen eigenen Container und damit
  eigene Juice-Shop-Datenbank/Challenge-State bekommt.
- Zugriffe sollten auf die eigene Lab-VM beschraenkt bleiben.
- Fuer Reset/Neuaufbau kann der Stack geloescht und neu erstellt werden.
