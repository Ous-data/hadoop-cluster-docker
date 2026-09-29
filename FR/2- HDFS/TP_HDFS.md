
```markdown
# 📚 Travail Pratique : Analyse d'HDFS, Blocs et Résilience

## Objectifs
* Voir comment un fichier est découpé en blocs et distribué sur le réseau.
* Tester les signaux de vie (*Heartbeats*) et forcer un inventaire (*Blockreports*).
* Bloquer le cluster avec le *Safemode* et observer la mémoire avec `FsImage` + `EditLog`.

---

## Phase 1 : Architecture Fondamentale, Métadonnées et Blocs

### Étape 0 : Prérequis (Facultatif)
Démarrez le conteneur `hadoop-master` s’il n’est pas déjà en cours d’exécution :
```powershell
docker start hadoop-master

```

Démarrez HDFS s’il n’est pas déjà en cours d’exécution :

```bash
start-dfs.sh

```

Assurez-vous que les Datanodes sont démarrés :

```bash
docker exec -it hadoop-worker1 bash
jps

```

Si le `DataNode` n'apparaît pas dans la liste, lancez le service :

```bash
$HADOOP_HOME/sbin/hadoop-daemon.sh start datanode

```

*>> Répétez la même procédure pour `worker2`.*

---

### Étape 1 : Créer et injecter un fichier découpé en blocs

Pour observer le découpage sans saturer vos machines, nous forçons des blocs minuscules de **1 Mo** (1 048 576 octets).

1. Connectez-vous dans le terminal du conteneur maître :
```powershell
docker exec -it hadoop-master bash

```


2. Créez un petit fichier texte d'environ 3 Mo :
```bash
yes "Ceci est une ligne de test pour Hadoop" | head -n 80000 > /tmp/monfichier.txt

```


*(Cette commande génère un texte en boucle et en conserve les 80 000 premières lignes).*
3. Envoyez-le dans HDFS avec des blocs de 1 Mo :
```bash
hdfs dfs -Ddfs.blocksize=1048576 -put /tmp/monfichier.txt /monfichier.txt

```



---

### Étape 2 : Inspection des Métadonnées avec `fsck`

Le NameNode connaît l'emplacement de chaque morceau sans stocker le fichier lui-même.

Demandez au NameNode où sont rangés les blocs :

```bash
hdfs fsck /monfichier.txt -files -blocks -locations

```

> **À noter sur votre feuille :**
> * Combien de blocs composent ce fichier ?
> * Quel est l'identifiant du premier bloc (ex: `blk_...`) ?
> * Sur quel nœud (`worker1`, etc.) se trouve ce bloc ?
> 
> 

---

### Étape 3 : Découverte des blocs physiques sur le DataNode

Les vraies données sont stockées sur les workers, pas sur le maître !

1. Ouvrez un deuxième terminal PowerShell et entrez dans le conteneur worker :


```powershell
docker exec -it hadoop-worker1 bash

```


2. Cherchez le bloc sur le disque dur du worker :


```bash
find / -name "blk_*" 2>/dev/null

```



> **Constat :** Vous voyez votre bloc sous la forme d'un simple fichier binaire Linux, accompagné d'un fichier `.meta` (qui contient la somme de contrôle pour vérifier qu'il n'est pas corrompu).
> 
> 

---

## Phase 2 : Mécanismes Internes (*Heartbeats*, *Blockreports*, *Safemode*, *EditLog* & *FsImage*)

### Atelier 1 : *Safemode* (Mode sans échec)

Le *Safemode* est un verrou de sécurité : le système est en lecture seule.

1. Depuis `hadoop-master`, activez le *Safemode* manuellement :


```bash
hdfs dfsadmin -safemode enter

```


2. Essayez de créer un nouveau dossier :


```bash
hdfs dfs -mkdir /dossier_test

```


Constat : L'opération échoue avec un message d'erreur indiquant que le NameNode est en Safemode.


3. Essayez de lire le fichier existant :


```bash
hdfs dfs -cat /monfichier.txt | head -n 5

```


Constat : La lecture fonctionne ! Le mode protège les données contre les modifications mais autorise la consultation.


4. Sortez du *Safemode* :


```bash
hdfs dfsadmin -safemode leave

```



---

### Atelier 2 : *Heartbeats*, Panne de Nœud et Réplication

Les workers envoient un battement de cœur régulier au maître pour prouver qu'ils fonctionnent.

1. Affichez l'état des nœuds depuis `hadoop-master` :


```bash
hdfs dfsadmin -report

```


(Regardez la ligne `Last contact` de `hadoop-worker1` : le chiffre reste petit grâce aux Heartbeats réguliers).


2. Simulez une panne en éteignant le worker (depuis PowerShell) :


```powershell
docker stop hadoop-worker1

```


3. Relancez immédiatement le rapport sur `hadoop-master` :


```bash
hdfs dfsadmin -report

```


Constat : Le compteur `Last contact` grandit. Si le signal ne revient pas, le NameNode finira par déclarer le nœud "mort" et dupliquera ses données sur les autres machines.


4. Rallumez le worker :


```powershell
docker start hadoop-worker1

```



---

### Atelier 3 : *Blockreports* en Direct

Le *Blockreport* est l'inventaire que le worker transmet au NameNode.

Vous pouvez soit attendre 10 minutes 30 pour que `worker1` soit automatiquement déclaré inactif, soit forcer `hadoop-worker1` à renvoyer son inventaire au maître (depuis `hadoop-master`) :

```bash
hdfs dfsadmin -triggerBlockReport hadoop-worker1:9866

```

Observez la confirmation reçue par le NameNode :

```bash
hdfs dfsadmin -report

```

---

### Atelier 4 : Métadonnées Persistantes (`FsImage` + `EditLog`)

* **EditLog** : Le carnet qui note immédiatement chaque action.


* **FsImage** : La photo globale de tout le système de fichiers.



1. Créez une nouvelle action dans HDFS depuis `hadoop-master` :


```bash
hdfs dfs -touch /fichier_journal.txt

```


2. Vérifiez les fichiers dans le dossier système du NameNode :


```bash
ls -la /root/hdfs/namenode/current/

```


Constat : Vous voyez des fichiers `edits_inprogress_...` et un fichier `fsimage_...`.


3. Forcez la création d'un nouveau `FsImage` instantané (sauvegarde propre) :


```bash
hdfs dfsadmin -safemode enter
hdfs dfsadmin -saveNamespace
hdfs dfsadmin -safemode leave

```



---

## 📝 Questions de Validation

* **Q1** : Dans l'Étape 3, pourquoi le fichier binaire `blk_...` est-il présent sur `hadoop-worker1` et pas sur `hadoop-master` ?


* **Q2** : Pourquoi le NameNode refuse-t-il les écritures en mode *Safemode* ?


* **Q3** : Quel signal permet au NameNode de savoir si `hadoop-worker1` est toujours allumé ?


* **Q4** : Si le serveur redémarre subitement, à quoi servent les fichiers `FsImage` et `EditLog` combinés ?
