#!/bin/bash

# Démarrage du service SSH
service ssh start

# Formatage du NameNode si nécessaire
if [ ! -d "/opt/hadoop/data/nameNode/current" ]; then
    echo "=== Formatage du NameNode ==="
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

# Démarrage de HDFS (NameNode, DataNode, SecondaryNameNode)
echo "=== Démarrage de HDFS ==="
$HADOOP_HOME/sbin/start-dfs.sh

# Démarrage de YARN (ResourceManager, NodeManager)
echo "=== Démarrage de YARN ==="
$HADOOP_HOME/sbin/start-yarn.sh

echo "=== Cluster Hadoop opérationnel ==="
# Garder le conteneur en cours d'exécution
tail -f /opt/hadoop/logs/*.log