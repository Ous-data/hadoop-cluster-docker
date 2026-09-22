# 📚 FAQ - Cours HDFS & Hadoop

Ce document rassemble les questions et réponses fréquemment posées dans le cadre du cours sur l'écosystème Hadoop et le système de fichiers distribué HDFS.

---

### Q1 - Comment le Standby NameNode est-il synchronisé avec l'Active NameNode ?

**Réponse :** 
Le Standby NameNode (SNN) maintient son état synchronisé avec l'Active NameNode principalement grâce aux **JournalNodes (JN)** ou à un stockage partagé :
* **Enregistrement des modifications :** L'Active NameNode consigne chaque modification de l'espace de noms (transactions) dans un journal d'édition appelé *EditLog*. Chaque écriture est immédiatement envoyée (*streaming*) aux JournalNodes.
* **Lecture en continu :** Le Standby NameNode lit en permanence ces journaux d'édition depuis les JournalNodes et applique les changements à sa propre mémoire pour conserver une image exacte et actualisée du système de fichiers.
* **Rapports des blocs :** Les DataNodes envoient leurs battements de cœur (*Heartbeats*) et leurs rapports de blocs (*Blockreports*) simultanément aux deux NameNodes (Active et Standby) afin que le Standby connaisse l'emplacement exact des blocs de données.

---

### Q2 - C'est quoi la différence entre un Secondary NameNode et un Standby NameNode ?

**Réponse :** 
Bien que ces deux rôles évitent la perte de données, leurs fonctions sont totalement différentes :
* **Secondary NameNode :** Il ne s'agit **pas** d'un nœud de secours en cas de panne (*pas de Haute Disponibilité*). Son rôle unique est d'alléger l'Active NameNode en fusionnant périodiquement l'image du système de fichiers (`FSImage`) et le journal des transactions (`EditLog`) pour éviter que ce dernier ne devienne trop volumineux.
* **Standby NameNode :** Il s'agit d'un nœud de secours à chaud (*Hot Standby*) dans une architecture de Haute Disponibilité (HA). Il garde une copie exacte de l'état du NameNode en mémoire et est prêt à basculer (*Failover*) instantanément pour prendre le relais si l'Active NameNode tombe en panne.

---

### Q3 - Comment les Heartbeats sont-ils réalisés, sous forme de ping, ou de petits paquets TCP ?

**Réponse :** 
Les *heartbeats* (battements de cœur) ne sont pas de simples pings réseau de niveau 3 (ICMP), mais des **appels de procédure distante (RPC) encapsulés dans des connexions TCP applicatives** :
* Ils sont envoyés de manière périodique (par défaut toutes les 3 secondes) par chaque DataNode vers le NameNode.
* En plus de signaler que le DataNode est bien vivant, ces messages transportent des métadonnées essentielles, telles que la capacité de stockage totale, l'espace disque disponible et le nombre de transferts en cours.
* Si le NameNode ne reçoit plus de heartbeat d'un DataNode au bout d'un certain délai de sécurité (*timeout*), il considère le nœud comme mort et déclenche la réplication des blocs perdus.

---

### Q4 - Comment la communication entre les nœuds s'effectue-t-elle : à travers TCP, adresse IP ou DNS ?

**Réponse :** 
La communication au sein du cluster Hadoop repose sur une combinaison de ces technologies :
* **TCP et Adresses IP :** Toutes les transmissions de données (entre client et DataNodes, ou entre DataNodes lors du pipeline de réplication) et les requêtes RPC s'effectuent au niveau de la couche transport via des sockets **TCP** connectées à des ports spécifiques (ex: port 8020 pour le NameNode).
* **DNS et Noms d'hôtes :** Hadoop utilise activement la résolution de noms (**DNS** ou le fichier local `/etc/hosts`) pour identifier et référencer les machines. Les fichiers de configuration (`core-site.xml`, `hdfs-site.xml`, etc.) s'appuient généralement sur les noms d'hôtes pour faciliter la gestion du cluster.

---

### Q5 - Quand un fichier est transféré dans HDFS, est-ce qu'il est stocké en premier lieu sur le NameNode ?

**Réponse :** 
**Non, absolument pas.** Le NameNode ne stocke jamais le contenu des fichiers de données.
* **Le rôle du NameNode :** Lorsqu'un client souhaite écrire un fichier, il contacte d'abord le NameNode pour obtenir l'autorisation et la liste des **DataNodes** cibles où stocker les différents blocs du fichier. Le NameNode gère uniquement les métadonnées (arborescence, permissions, localisation des blocs).
* **Le transfert par Streaming :** Le contenu du fichier (découpé en blocs) est ensuite transmis **directement du client vers les DataNodes** en mode **streaming** via TCP, en suivant un pipeline de réplication d'un DataNode à un autre. Cela évite que le NameNode ne devienne un goulot d'étranglement pour le réseau.

---

### Q6 - Quel est le rôle exact du Secondary NameNode lors de la fusion (Checkpointing) ?

**Réponse :** 
Le Secondary NameNode télécharge régulièrement l'image du système de fichiers (`FSImage`) et le fichier de journalisation des transactions en cours (`EditLog`) depuis l'Active NameNode. Il les combine dans sa propre mémoire pour générer un nouveau fichier d'image fusionné (`FSImage.ckpt`), qu'il renvoie ensuite à l'Active NameNode. Cela permet de réduire la taille de l'EditLog et d'accélérer le prochain redémarrage du NameNode.

---

### Q7 - Comment les DataNodes communiquent-ils entre eux lors de l'écriture d'un gros fichier dans HDFS ?

**Réponse :** 
Lors de l'écriture d'un fichier, les DataNodes communiquent via un système de **pipeline de réplication** :
* Le client découpe le fichier en blocs et envoie le premier bloc au premier DataNode par flux TCP.
* Dès que ce premier DataNode reçoit les premiers paquets, il les transmet simultanément au deuxième DataNode de la liste, qui les transmet à son tour au troisième (en fonction du facteur de réplication configuré, généralement 3).
* Cette transmission en cascade (*pipelining*) s'effectue en temps réel pour optimiser la bande passante du réseau.

---

### Q8 - Que se passe-t-il si un DataNode s'arrête brutalement pendant le traitement d'une tâche ?

**Réponse :** 
Le mécanisme de tolérance aux pannes de Hadoop réagit de la manière suivante :
* **Détection :** Le NameNode constate l'absence de *heartbeats* de la part du DataNode défaillant (dépassant le délai limite ou *timeout*).
* **Mise à jour de la topologie :** Le NameNode identifie tous les blocs de données dont ce nœud était l'unique ou l'un des détenteurs.
* **Réplication de secours :** Le NameNode ordonne aux autres DataNodes possédant les répliques saines de dupliquer ces blocs vers de nouveaux nœuds opérationnels afin de rétablir le facteur de réplication initial et de garantir la sécurité des données.

---

### Q9 - Qu'appelle-t-on la localité des données (*Data Locality*) dans l'écosystème Hadoop ?

**Réponse :** 
La localité des données est un principe fondamental d'optimisation des performances qui consiste à **exécuter les calculs (tâches MapReduce ou Spark) sur la machine même (le DataNode) où se trouvent physiquement stockées les données** à traiter. 
* Cela évite de saturer le réseau de l'entreprise en transférant de lourds volumes de données d'un serveur à un autre.
* Le framework privilégie toujours le traitement local (*node-local*), puis sur le même rack (*rack-local*), et en dernier recours seulement via le réseau externe.

---

### Q10 - Quel composant de Hadoop gère l'allocation des ressources et la planification des tâches (Resource Management) ?

**Réponse :** 
C'est **YARN** (*Yet Another Resource Negotiator*) qui gère cette partie depuis Hadoop 2.0 :
* **ResourceManager (RM) :** Le composant maître global qui arbitre et alloue les ressources de calcul (CPU, mémoire) à travers l'ensemble du cluster.
* **NodeManager (NM) :** L'agent exécuté sur chaque nœud esclave qui surveille l'utilisation des ressources locales et gère les conteneurs d'exécution pour les tâches confiées.