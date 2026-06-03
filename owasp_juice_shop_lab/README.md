# DoziLab OWASP Juice Shop Lab

Diese App stellt eine isolierte OWASP Juice Shop Instanz fuer Web-Security- und
Pentesting-Grundlagen bereit. Sie ist als Trainingsziel fuer eigene
Lehrveranstaltungen gedacht.

Wichtig: Die App ist bewusst verwundbar. Sie soll nur in der bereitgestellten
Lab-VM und nur im erlaubten Kurs-/Campusnetz verwendet werden. Sie ist nicht als
allgemeine Angriffsumgebung fuer fremde Ziele gedacht.

## Ueberblick

Die App erstellt:

- eine Ubuntu-VM
- Docker
- OWASP Juice Shop als Container
- Nginx als Reverse Proxy auf Port 80
- SSH-Zugriff nur aus `ssh_cidr`
- Webzugriff nur aus `web_cidr`
- READY/FAILED-Marker im Console Log

Es werden keine Cinder Volumes erstellt.

## Struktur

```text
owasp_juice_shop_lab/
├── app.yaml
├── env.yaml
├── heat/
│   └── main.yaml
└── cloud-init/
    └── user-data.yaml
```

## Zugriff

Juice Shop:

```text
http://<floating_ip>/
```

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
- Zugriffe sollten auf die eigene Lab-VM beschraenkt bleiben.
- Fuer Reset/Neuaufbau kann der Stack geloescht und neu erstellt werden.
