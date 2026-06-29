# DoziLab Jupyter Data Science Lab

Diese App stellt eine Jupyter-Umgebung fuer Python- und Data-Science-Kurse
bereit. Sie erstellt eine Ubuntu-VM, installiert JupyterHub/JupyterLab und legt
Kursbenutzer aus den vom Backend erzeugten `deployment_groups` an.

Die VM bootet von einem Cinder Root-Volume. Userdaten liegen unter
`/home/<user>`.

## Struktur

```text
ansible_jupyter_datascience_lab/
├── app.yaml
├── env.yaml
├── heat/
│   └── main.yaml
└── playbooks/
    └── main.yml
```

## Funktionen

- eine Ubuntu-VM
- JupyterHub ueber HTTP
- JupyterLab fuer jeden angelegten User
- lokale User aus `deployment_groups[].linux`
- Teacher-User aus `teacher.linux`
- optionale Beispiel-Notebooks im Arbeitsordner
- READY/FAILED-Marker unter `/var/lib/dozilab`

## Backend-Credentials

`app.yaml` nutzt den gleichen Credential-Vertrag wie `ansible_multiuser`:

- pro Gruppe: `deployment_groups[].username` und `deployment_groups[].linux.password`
- Teacher: `teacher.linux.username` und `teacher.linux.password`

Das Playbook erzeugt daraus intern `/etc/dozilab/user.json`, damit die
bestehende Jupyter-Provisionierung weiterverwendet werden kann.

## Zugriff

JupyterHub:

```text
http://<floating_ip>/
```

Admin-SSH:

```bash
ssh -i ~/.ssh/heat-bastion-key.pem ubuntu@<floating_ip>
```

Passwort-SSH fuer Kursbenutzer ist deaktiviert. Die Kursbenutzer melden sich
ueber JupyterHub an.

## Pakete

Installiert werden JupyterHub/JupyterLab und typische Data-Science-Pakete wie
`numpy`, `pandas`, `matplotlib`, `scipy`, `scikit-learn` und `seaborn`.
