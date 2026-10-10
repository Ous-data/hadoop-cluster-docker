## ❓ Foire Aux Questions (FAQ) - Hadoop MapReduce

Vous trouverez ici les réponses aux questions les plus fréquemment posées par les étudiants concernant l'exécution et le débogage des jobs MapReduce.

---

### 1. Quelle est la différence entre un `Mapper` et un `Reducer` ?
* **Mapper :** Il traite les données d'entrée en parallèle, bloc par bloc (ou ligne par ligne). Son rôle est d'analyser les données brutes et d'émettre des paires **clé-valeur intermédiaires** (`key-value pairs`) via la méthode `context.write(key, value)`.
* **Reducer :** Il reçoit toutes les valeurs regroupées et triées associées à une **même clé** unique (provenant des Mappers après l'étape de *Shuffle and Sort*). Il effectue ensuite une opération d'agrégation (somme, moyenne, maximum, etc.) pour produire le résultat final.

---

### 2. Qu'est-ce que l'étape de *Shuffle and Sort* et pourquoi est-elle critique ?
Le *Shuffle and Sort* est la phase intermédiaire automatique gérée par le framework Hadoop entre la fin des Mappers et le début des Reducers :
* **Shuffle :** Les données de sortie des Mappers sont collectées, transférées et redistribuées sur le réseau pour que toutes les valeurs d'une même clé soient envoyées au même Reducer.
* **Sort :** Les clés sont automatiquement triées par ordre croissant avant d'être transmises au Reducer.
* **Impact :** C'est souvent le **goulot d'étranglement** (bottleneck) de performance principal car il génère beaucoup de trafic réseau. Une bonne conception des clés permet de minimiser cette surcharge.

---

### 3. Pourquoi mon job MapReduce est-il bloqué à 0 % ou 99 % ?
* **Bloqué à 0 % (au lancement) :** 
  * Vérifiez que vos daemons YARN (ResourceManager et NodeManagers) ainsi que HDFS (NameNode et DataNodes) sont bien actifs dans votre cluster Docker.
  * Assurez-vous que le chemin du fichier d'entrée spécifié dans la commande `hadoop jar` existe bien dans HDFS (`hdfs dfs -ls /chemin`).
* **Bloqué à 99 % (en fin de parcours) :** 
  * C'est un comportement classique. Le job a terminé tous ses Mappers et Reducers, mais il procède au nettoyage des fichiers temporaires, à la validation des blocs ou à l'écriture finale des résultats. Patientez quelques instants.

---

### 4. Comment puis-je déboguer un job qui échoue (*failed*) sans message d'erreur clair ?
* **Consultez les logs de l'application YARN :** Utilisez la commande suivante dans votre terminal conteneurisé pour afficher l'historique des erreurs de la dernière application :
  ```bash
  yarn logs -applicationId <application_id>