# DoziLab Jupyter Data Science Lab

Diese App stellt eine Jupyter-Umgebung fuer Python- und Data-Science-Kurse
bereit. Sie erstellt eine Ubuntu-VM, installiert JupyterHub/JupyterLab und legt
Kursbenutzer aus `user_json` an.

Die App erstellt bewusst keine Cinder Volumes. Die VM bootet direkt vom Image;
Userdaten liegen unter `/home/<user>`.

## Struktur

```text
jupyter_datascience_lab/
├── app.yaml
├── env.yaml
├── heat/
│   └── main.yaml
└── cloud-init/
    └── user-data.yaml
```

## Funktionen

- eine Ubuntu-VM
- JupyterHub ueber HTTP
- JupyterLab fuer jeden angelegten User
- lokale User aus `instance.credentials`
- optionaler Teacher-User aus `instance.admin_credentials`
- optionale Beispiel-Notebooks im Arbeitsordner
- READY/FAILED-Marker im Console Log

## user_json Beispiel

```json
{
  "course_label": "Data Science Kurs 2026",
  "instance": {
    "credentials": [
      { "username": "gruppe01", "password": "User01_2026!" }
    ],
    "admin_credentials": {
      "username": "teacher",
      "password": "TeacherPw_2026!"
    }
  },
  "applications": []
}
```

`user_json` kann als Raw-JSON oder Base64-kodiertes JSON uebergeben werden.

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
