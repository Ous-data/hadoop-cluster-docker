
```markdown
# Hadoop & Big Data Labs (Docker)

This GitHub repository hosts Docker configurations, guides, and environments for practical lab sessions (TPs) dedicated to Hadoop (HDFS, YARN, and MapReduce).

📂 Repository Structure

.
├── Dockerfile                  # Builds the Hadoop image (Ubuntu + OpenJDK + Hadoop)
├── docker-compose.yml          # Orchestrates the pseudo-distributed cluster
├── entrypoint.sh               # Initialization script (NameNode formatting, service startup)
├── config/                     # Hadoop XML configuration files
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── yarn-site.xml
│   └── mapred-site.xml
└── labs/                       # Instructions and scripts for the various lab sessions
    ├── hdfs/                   # Distributed file system manipulation
    ├── yarn/                   # Resource management and job submission
    └── mapreduce/              # Distributed processing execution (e.g., Pi job, WordCount)

⚙️ Prerequisites

Before getting started, make sure you have the following installed on your machine:
- Docker
- Docker Compose

🛠️ Setting Up the Cluster on Docker

1. **Retrieve the files:** Download the ZIP archive of this repository from GitHub (or directly place the `Dockerfile`, `docker-compose.yml`, `entrypoint.sh`, and the `config/` folder) into a working directory on your machine.
2. **Build the image and start the cluster:** Navigate to the folder containing these files in your terminal, then run the build and startup command:
   ```bash
   docker compose up --build -d

```

3. **Verify running processes (`jps`):**
```bash
docker exec -it hadoop-node jps

```


You should see the following active services: NameNode, DataNode, SecondaryNameNode, ResourceManager, and NodeManager.
4. **Access the Hadoop container terminal:**
```bash
docker exec -it hadoop-node bash

```



🌐 Web Interfaces (UI)

Once the cluster is up and running, you can monitor your services via your browser:

* **HDFS NameNode UI:** http://localhost:9870
* **YARN ResourceManager UI:** http://localhost:8088

📚 Lab Content

* **HDFS Lab:** Creating directory trees, uploading files (`hdfs dfs -put`), checking blocks (`hdfs fsck`), and managing the replication factor (`-setrep`).
* **YARN Lab:** Submitting applications, monitoring containers, and analyzing execution metrics.
* **MapReduce Lab:** Launching sample jobs (computing Pi, word count) and leveraging the framework.

💡 Author & Context

Educational project designed for learning Big Data technologies and administering containerized distributed clusters.

```

```