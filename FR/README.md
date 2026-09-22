# Hadoop & Big Data Labs (Docker)

Ce dépôt GitHub héberge les configurations Docker ainsi que les supports et environnements pour les travaux pratiques (TP) consacrés à **Hadoop (HDFS, YARN et MapReduce)**.

---

## 📂 Structure du Dépôt

```text
.
├── Dockerfile                  # Construction de l'image Hadoop (Ubuntu + OpenJDK + Hadoop)
├── docker-compose.yml          # Orchestration du cluster pseudo-distribué
├── entrypoint.sh               # Script d'initialisation (formatage NameNode, démarrage services)
├── config/                     # Fichiers de configuration XML d'Hadoop
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── yarn-site.xml
│   └── mapred-site.xml
└── labs/                       # Instructions et scripts des différents laboratoires
    ├── hdfs/                   # Manipulation du système de fichiers distribué
    ├── yarn/                   # Gestion des ressources et soumission de jobs
    └── mapreduce/              # Exécution de traitements distribués (ex: Job Pi, WordCount)

```

---

## ⚙️ Prérequis

Avant de démarrer, assurez-vous d'avoir installé sur votre machine :

* [Docker](https://www.google.com/search?q=https://www.docs.docker.com/get-docker/&utm_source=gemini)
* [Docker Compose](https://docs.docker.com/compose/install/?utm_source=gemini)

---
🛠️ Création du Cluster sur Docker

Récupération des fichiers :
Téléchargez l'archive ZIP de ce dépôt depuis GitHub (ou récupérez directement les fichiers Dockerfile, docker-compose.yml, entrypoint.sh ainsi que le dossier config/) dans un répertoire de travail sur votre machine.

Construction de l'image et démarrage du cluster :
Placez-vous dans le dossier contenant ces fichiers dans votre terminal, puis lancez la construction et le démarrage des services :

Bash
docker compose up --build -d
Vérification du bon fonctionnement des processus (jps) :

Bash
docker exec -it hadoop-node jps
Vous devez y voir les services actifs : NameNode, DataNode, SecondaryNameNode, ResourceManager et NodeManager.

Accès au terminal du conteneur Hadoop :

Bash
docker exec -it hadoop-node bash

---

## 🌐 Interfaces Web (UI)

Une fois le cluster lancé, vous pouvez monitorer vos services via votre navigateur :

* **HDFS NameNode UI :** [http://localhost:9870](http://localhost:9870?utm_source=gemini)
* **YARN ResourceManager UI :** [http://localhost:8088](http://localhost:8088?utm_source=gemini)

---

## 📚 Contenu des Labs

* **Lab HDFS :** Création d'arborescences, injection de fichiers (`hdfs dfs -put`), vérification des blocs (`hdfs fsck`) et gestion du facteur de réplication (`-setrep`).
* **Lab YARN :** Soumission d'applications, suivi des conteneurs et analyse des métriques d'exécution.
* **Lab MapReduce :** Lancement de jobs d'exemple (calcul de $\pi$, comptage de mots) et exploitation du framework.

---

## 💡 Auteur & Contexte

Projet pédagogique conçu pour l'apprentissage des technologies Big Data et l'administration de clusters distribués conteneurisés.
