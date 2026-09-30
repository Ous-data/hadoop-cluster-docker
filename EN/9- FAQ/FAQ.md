```markdown
# 📚 FAQ - Hadoop Course (HDFS, YARN, MapReduce)[cite: 8]

This document compiles frequently asked questions and answers for the course on the Hadoop ecosystem (HDFS + YARN + MAPREDUCE).[cite: 8]

---

### Q1 - How is the Standby NameNode synchronized with the Active NameNode?[cite: 8]

**Answer:**[cite: 8]
The Standby NameNode (SNN) keeps its state synchronized with the Active NameNode primarily through **JournalNodes (JN)** or shared storage:[cite: 8]
* **Logging modifications:** The Active NameNode records every namespace modification (transactions) in an edit log called *EditLog*. Each write is immediately sent (*streamed*) to the JournalNodes.[cite: 8]
* **Continuous reading:** The Standby NameNode continuously reads these edit logs from the JournalNodes and applies the changes to its own memory to maintain an exact and up-to-date image of the file system.[cite: 8]
* **Block reports:** DataNodes send their heartbeats (*Heartbeats*) and block reports (*Blockreports*) simultaneously to both NameNodes (Active and Standby) so that the Standby knows the exact location of the data blocks.[cite: 8]

---

### Q2 - What is the difference between a Secondary NameNode and a Standby NameNode?[cite: 8]

**Answer:**[cite: 8]
Although both roles prevent data loss, their functions are completely different:[cite: 8]
* **Secondary NameNode:** It is **not** a failover node (*no High Availability*). Its sole role is to lighten the load on the Active NameNode by periodically merging the file system image (`FSImage`) and the transaction log (`EditLog`) to prevent the latter from becoming too bulky.[cite: 8]
* **Standby NameNode:** It is a hot standby node (*Hot Standby*) in a High Availability (HA) architecture. It keeps an exact copy of the NameNode's state in memory and is ready to switch (*Failover*) instantly to take over if the Active NameNode fails.[cite: 8]

---

### Q3 - How are Heartbeats implemented, as pings or small TCP packets?[cite: 8]

**Answer:**[cite: 8]
Heartbeats are not simple Layer 3 network pings (ICMP), but **Remote Procedure Calls (RPC) encapsulated in application TCP connections**:[cite: 8]
* They are sent periodically (by default every 3 seconds) by each DataNode to the NameNode.[cite: 8]
* In addition to signaling that the DataNode is alive, these messages carry essential metadata, such as total storage capacity, available disk space, and the number of ongoing transfers.[cite: 8]
* If the NameNode stops receiving a heartbeat from a DataNode past a certain security timeout (*timeout*), it considers the node dead and triggers the replication of lost blocks.[cite: 8]

---

### Q4 - How does communication between nodes occur: through TCP, IP address, or DNS?[cite: 8]

**Answer:**[cite: 8]
Communication within the Hadoop cluster relies on a combination of these technologies:[cite: 8]
* **TCP and IP Addresses:** All data transmissions (between client and DataNodes, or between DataNodes during the replication pipeline) and RPC requests take place at the transport layer via **TCP** sockets connected to specific ports (e.g., port 8020 for the NameNode).[cite: 8]
* **DNS and Hostnames:** Hadoop actively uses name resolution (**DNS** or the local `/etc/hosts` file) to identify and reference machines. Configuration files (`core-site.xml`, `hdfs-site.xml`, etc.) generally rely on hostnames to simplify cluster management.[cite: 8]

---

### Q5 - When a file is transferred into HDFS, is it stored first on the NameNode?[cite: 8]

**Answer:**[cite: 8]
**No, absolutely not.** The NameNode never stores the content of data files.[cite: 8]
* **The role of the NameNode:** When a client wants to write a file, it first contacts the NameNode to get authorization and the list of target **DataNodes** where the file's various blocks should be stored. The NameNode only manages metadata (directory tree, permissions, block locations).[cite: 8]
* **Streaming transfer:** The file content (split into blocks) is then transmitted **directly from the client to the DataNodes** in **streaming** mode via TCP, following a replication pipeline from one DataNode to another. This prevents the NameNode from becoming a network bottleneck.[cite: 8]

---

### Q6 - What is the exact role of the Secondary NameNode during checkpointing?[cite: 8]

**Answer:**[cite: 8]
The Secondary NameNode regularly downloads the file system image (`FSImage`) and the current transaction log file (`EditLog`) from the Active NameNode. It combines them in its own memory to generate a new merged image file (`FSImage.ckpt`), which it then sends back to the Active NameNode. This reduces the size of the EditLog and speeds up the next restart of the NameNode.[cite: 8]

---

### Q7 - How do DataNodes communicate with each other when writing a large file into HDFS?[cite: 8]

**Answer:**[cite: 8]
When writing a file, DataNodes communicate via a **replication pipeline** system:[cite: 8]
* The client splits the file into blocks and sends the first block to the first DataNode via a TCP stream.[cite: 8]
* As soon as this first DataNode receives the first packets, it simultaneously forwards them to the second DataNode in the list, which in turn forwards them to the third (depending on the configured replication factor, usually 3).[cite: 8]
* This cascading transmission (*pipelining*) happens in real time to optimize network bandwidth.[cite: 8]

---

### Q8 - What happens if a DataNode abruptly shuts down while processing a task?[cite: 8]

**Answer:**[cite: 8]
Hadoop's fault tolerance mechanism reacts as follows:[cite: 8]
* **Detection:** The NameNode notices the absence of heartbeats from the failing DataNode (exceeding the time limit or *timeout*).[cite: 8]
* **Topology update:** The NameNode identifies all data blocks of which this node was the sole or one of the holders.[cite: 8]
* **Backup replication:** The NameNode instructs other DataNodes holding healthy replicas to duplicate these blocks to new operational nodes to restore the initial replication factor and ensure data safety.[cite: 8]

---

### Q9 - What is called Data Locality in the Hadoop ecosystem?[cite: 8]

**Answer:**[cite: 8]
Data locality is a fundamental performance optimization principle that consists of **running computations (MapReduce or Spark tasks) on the exact same machine (the DataNode) where the data to be processed is physically stored**.[cite: 8]
* This avoids saturating the corporate network by transferring heavy volumes of data from one server to another.[cite: 8]
* The framework always prioritizes local processing (*node-local*), then on the same rack (*rack-local*), and only as a last resort via the external network.[cite: 8]

---

### Q10 - Which Hadoop component manages resource allocation and task scheduling (Resource Management)?[cite: 8]

**Answer:**[cite: 8]
It is **YARN** (*Yet Another Resource Negotiator*) that has managed this part since Hadoop 2.0:[cite: 8]
* **ResourceManager (RM):** The global master component that arbitrates and allocates compute resources (CPU, memory) across the entire cluster.[cite: 8]
* **NodeManager (NM):** The agent running on each slave node that monitors local resource usage and manages execution containers for the assigned tasks.[cite: 8]

---

### Q11: What is the fundamental difference between MapReduce and the Application Master?[cite: 8]

**Answer:**[cite: 8]
* **MapReduce** is the programming model and compute engine (the algorithmic "brain"). It defines *how* data must be processed through filtering (*Map*) and aggregation (*Reduce*) phases.[cite: 8]
* **The Application Master (AM)** is a temporary orchestration manager provided by YARN. Its role is not to compute data, but to coordinate the job execution, negotiate resources, and supervise the smooth running of the processing.[cite: 8]

---

### Q12: How do the Application Master and MapReduce work together during job execution?[cite: 8]

**Answer:**[cite: 8]
They collaborate closely via YARN through the following steps:[cite: 8]
1. The client submits the MapReduce job to the **ResourceManager**.[cite: 8]
2. The ResourceManager launches the **Application Master** in a first container.[cite: 8]
3. The Application Master analyzes the data volume and asks the ResourceManager to allocate additional containers (CPU and memory) on the cluster nodes.[cite: 8]
4. It then commands the execution of **Map** tasks and coordinates the **Reduce** tasks of the MapReduce code.[cite: 8]
5. Finally, it monitors progress, handles any task failures, and notifies when the job is finished.[cite: 8]

```