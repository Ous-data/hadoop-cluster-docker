
```markdown
# 📚 TP Pratique : Premier Job MapReduce (WordCount) avec Hadoop, HDFS et YARN

## Objectif du TP
Comprendre le rôle de chaque brique de l'écosystème Hadoop à travers l'exemple classique du décompte de mots (*WordCount*)[cite: 7] :
* **Machine locale (Hôte)** : Préparer les données brutes[cite: 7].
* **Docker** : Conteneur hébergeant l'environnement Hadoop[cite: 7].
* **HDFS** : Stocker le fichier de manière distribuée[cite: 7].
* **YARN** : Allouer les conteneurs et coordonner le calcul[cite: 7].
* **MapReduce** : Exécuter le filtre (`Map`) et l'agrégation (`Reduce`)[cite: 7].

---

## Étape 1 : Créer le fichier texte sur votre machine hôte (Windows / Mac)
Ouvrez un éditeur de texte standard (Bloc-notes, VS Code, TextEdit) ou un terminal local (PowerShell ou Terminal Mac)[cite: 7].

Créez un fichier nommé `input.txt` et collez-y les lignes suivantes[cite: 7] :
```plaintext
hadoop hdfs yarn 
mapreduce hadoop hdfs 
yarn hadoop docker docker 
hadoop mapreduce

```

Enregistrez le fichier dans un dossier facilement accessible (par exemple sur votre Bureau ou dans votre dossier utilisateur).

---

## Étape 2 : Transférer le fichier de votre machine vers le conteneur Docker

Ouvrez votre terminal (PowerShell sur Windows ou Terminal sur macOS), placez-vous dans le dossier contenant `input.txt` et exécutez la commande suivante :

```powershell
docker cp input.txt <NOM_DU_CONTENEUR_NAMENODE>:/tmp/input.txt

```

> **Astuce** : Remplacez `<NOM_DU_CONTENEUR_NAMENODE>` par le nom ou l'ID de votre conteneur Hadoop (par exemple `namenode` ou `hadoop-master`). Pour retrouver son nom exact, tapez `docker ps`.
> 
> 

Connectez-vous ensuite à l'intérieur du conteneur :

```powershell
docker exec -it <NOM_DU_CONTENEUR_NAMENODE> bash

```

Vérifiez que le fichier est bien présent dans le système de fichiers local du conteneur :

```bash
cat /tmp/input.txt

```

---

## Étape 3 : Charger le fichier depuis le conteneur vers HDFS

Le fichier se trouve actuellement sur le disque local du conteneur. Il faut le transférer dans le système de fichiers distribué HDFS.

1. Créez un répertoire d'entrée dans HDFS :


```bash
hdfs dfs -mkdir -p /input

```


2. Copiez le fichier `/tmp/input.txt` vers HDFS :


```bash
hdfs dfs -put /tmp/input.txt /input/

```


3. Vérifiez que le fichier est bien présent dans HDFS :


```bash
hdfs dfs -ls /input

```



---

## Étape 4 : Exécuter le job WordCount via MapReduce et YARN

Hadoop intègre nativement un fichier JAR d'exemples comprenant l'algorithme *WordCount*.

Lancez le job MapReduce en indiquant le dossier d'entrée HDFS et le dossier de sortie :

```bash
hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input/input.txt /output

```

* `/usr/local/.../hadoop-mapreduce-examples-3.3.6.jar` : Le chemin vers le fichier JAR contenant une collection de programmes d'exemples précompilés fournis par Hadoop.


* `wordcount` : Le nom du programme d'exemple à exécuter (qui compte le nombre d'occurrences de chaque mot dans le texte).



> **Ce qui se passe en coulisses :**
> 1. Le client contacte le *ResourceManager* de YARN.
> 
> 
> 2. YARN alloue un conteneur pour démarrer l'*ApplicationMaster*.
> 
> 
> 3. L'*ApplicationMaster* demande des conteneurs supplémentaires pour exécuter les tâches `Map` et `Reduce`.
> 
> 
> 4. Les résultats finaux sont écrits par les réducteurs directement dans le dossier HDFS `/output`.
> 
> 
> 
> 

Pendant ou juste après l'exécution, observez l'interface de suivi YARN sur votre navigateur hôte à l'adresse :

👉 **`http://localhost:8088`**

Vous verrez votre application à l'état `RUNNING` puis `FINISHED` (`SUCCEEDED`).

---

## Étape 5 : Consulter et récupérer les résultats

1. Listez le contenu du répertoire de sortie HDFS généré par le job :


```bash
hdfs dfs -ls /output

```


(Vous devez voir deux éléments : `_SUCCESS` (indicateur de fin sans erreur) et `part-r-00000` (le fichier contenant les comptages)).


2. Affichez le résultat directement depuis HDFS dans la console :


```bash
hdfs dfs -cat /output/part-r-00000

```


3. Exportez le résultat depuis HDFS vers le disque local du conteneur :


```bash
hdfs dfs -get /output/part-r-00000 /tmp/resultat.txt

```


4. Quittez le conteneur Docker :


```bash
exit

```


5. Depuis le terminal de votre machine hôte (Windows/Mac), téléchargez le fichier de résultats sur votre ordinateur :


```bash
docker cp <NOM_DU_CONTENEUR_NAMENODE>:/tmp/resultat.txt ./resultat.txt

```



Le contenu du fichier de résultat attendu ressemble à ceci :

```plaintext
docker       2
hadoop       4
hdfs         2
mapreduce    2
yarn         2

```

---

## 📝 Questions de synthèse pour valider la compréhension

* **Q1** : Rôle de HDFS : Pourquoi n'exécute-t-on pas MapReduce directement sur le fichier `/tmp/input.txt` du système d'exploitation ?


* **Q2** : Rôle de YARN : Quel composant a attribué la mémoire et le CPU nécessaires au conteneur exécutant le mot clé `wordcount` ?


* **Q3** : Comportement MapReduce : Si vous relancez exactement la même commande d'exécution à l'étape 4 sans supprimer le dossier `/output`, que se passe-t-il et pourquoi ?



```

```