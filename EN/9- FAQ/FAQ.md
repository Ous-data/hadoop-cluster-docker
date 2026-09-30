```markdown
# 📚 FAQ - Hadoop Course (HDFS, YARN, MapReduce)

This document compiles frequently asked questions and answers for the course on the Hadoop ecosystem (HDFS + YARN + MAPREDUCE).

---

### Q1 - How is the Standby NameNode synchronized with the Active NameNode?

**Answer:**
The Standby NameNode (SNN) keeps its state synchronized with the Active NameNode primarily through **JournalNodes (JN)** or shared storage:
* **Logging modifications:** The Active NameNode records every namespace modification (transactions) in an edit log called *EditLog*. Each write is immediately sent (*streamed*) to the JournalNodes.
* **Continuous reading:** The Standby NameNode continuously reads these edit logs from the JournalNodes and applies the changes to its own memory to maintain an exact and up-to-date image of the file system.
* **Block reports:** DataNodes send their heartbeats (*Heartbeats*) and block reports (*Blockreports*) simultaneously to both NameNodes (Active and Standby) so that the Standby knows the exact location of the data blocks.

---

### Q2 - What is the difference between a Secondary NameNode and a Standby NameNode?

**Answer:**
Although both roles prevent data loss, their functions are completely different:
* **Secondary NameNode:** It is **not** a failover node (*no High Availability*). Its sole role is to lighten the load on the Active NameNode by periodically merging the file system image (`FSImage`) and the transaction log (`EditLog`) to prevent the latter from becoming too bulky.
* **Standby NameNode:** It is a hot standby node (*Hot Standby*) in a High Availability (HA) architecture. It keeps an exact copy of the NameNode's state in memory and is ready to switch (*Failover*) instantly to take over if the Active NameNode fails.

---

### Q3 - How are Heartbeats implemented, as pings or small TCP packets?

**Answer:**
Heartbeats are not simple Layer 3 network pings (ICMP), but **Remote Procedure Calls (RPC) encapsulated in application TCP connections**:
* They are sent periodically (by default every 3 seconds) by each DataNode to the NameNode.
* In addition to signaling that the DataNode is alive, these messages carry essential metadata, such as total storage capacity, available disk space, and the number of ongoing transfers.
* If the NameNode stops receiving a heartbeat from a DataNode past a certain security timeout (*timeout*), it considers the node dead and triggers the replication of lost blocks.

---

### Q4 - How does communication between nodes occur: through TCP, IP address, or DNS?

**Answer:**
Communication within the Hadoop cluster relies on a combination of these technologies:
* **TCP and IP Addresses:** All data transmissions (between client and DataNodes, or between DataNodes during the replication pipeline) and RPC requests take place at the transport layer via **TCP** sockets connected to specific ports (e.g., port 8020 for the NameNode).
* **DNS and Hostnames:** Hadoop actively uses name resolution (**DNS** or the local `/etc/hosts` file) to identify and reference machines. Configuration files (`core-site.xml`, `hdfs-site.xml`, etc.) generally rely on hostnames to simplify cluster management.

---

### Q5 - When a file is transferred into HDFS, is it stored first on the NameNode?

**Answer:**
**No, absolutely not.** The NameNode never stores the content of data files.
* **The role of the NameNode:** When a client wants to write a file, it first contacts the NameNode to get authorization and the list of target **DataNodes** where the file's various blocks should be stored. The NameNode only manages metadata (directory tree, permissions, block locations).
* **Streaming transfer:** The file content (split into blocks) is then transmitted **directly from the client to the DataNodes** in **streaming** mode via TCP, following a replication pipeline from one DataNode to another. This prevents the NameNode from becoming a network bottleneck.

---

### Q6 - What is the exact role of the Secondary NameNode during checkpointing?

**Answer:**
The Secondary NameNode regularly downloads the file system image (`FSImage`) and the current transaction log file (`EditLog`) from the Active NameNode. It combines them in its own memory to generate a new merged image file (`FSImage.ckpt`), which it then sends back to the Active NameNode. This reduces the size of the EditLog and speeds up the next restart of the NameNode.

---

### Q7 - How do DataNodes communicate with each other when writing a large file into HDFS?

**Answer:**
When writing a file, DataNodes communicate via a **replication pipeline** system:
* The client splits the file into blocks and sends the first block to the first DataNode via a TCP stream.
* As soon as this first DataNode receives the first packets, it simultaneously forwards them to the second DataNode in the list, which in turn forwards them to the third (depending on the configured replication factor, usually 3).
* This cascading transmission (*pipelining*) happens in real time to optimize network bandwidth.

---

### Q8 - What happens if a DataNode abruptly shuts down while processing a task?

**Answer:**
Hadoop's fault tolerance mechanism reacts as follows:
* **Detection:** The NameNode notices the absence of heartbeats from the failing DataNode (exceeding the time limit or *timeout*).
* **Topology update:** The NameNode identifies all data blocks of which this node was the sole or one of the holders.
* **Backup replication:** The NameNode instructs other DataNodes holding healthy replicas to duplicate these blocks to new operational nodes to restore the initial replication factor and ensure data safety.

---

### Q9 - What is called Data Locality in the Hadoop ecosystem?

**Answer:**
Data locality is a fundamental performance optimization principle that consists of **running computations (MapReduce or Spark tasks) on the exact same machine (the DataNode) where the data to be processed is physically stored**.
* This avoids saturating the corporate network by transferring heavy volumes of data from one server to another.
* The framework always prioritizes local processing (*node-local*), then on the same rack (*rack-local*), and only as a last resort via the external network.

---

### Q10 - Which Hadoop component manages resource allocation and task scheduling (Resource Management)?

**Answer:**
It is **YARN** (*Yet Another Resource Negotiator*) that has managed this part since Hadoop 2.0:
* **ResourceManager (RM):** The global master component that arbitrates and allocates compute resources (CPU, memory) across the entire cluster.
* **NodeManager (NM):** The agent running on each slave node that monitors local resource usage and manages execution containers for the assigned tasks.

---

### Q11: What is the fundamental difference between MapReduce and the Application Master?

**Answer:**
* **MapReduce** is the programming model and compute engine (the algorithmic "brain"). It defines *how* data must be processed through filtering (*Map*) and aggregation (*Reduce*) phases.
* **The Application Master (AM)** is a temporary orchestration manager provided by YARN. Its role is not to compute data, but to coordinate the job execution, negotiate resources, and supervise the smooth running of the processing.

---

### Q12: How do the Application Master and MapReduce work together during job execution?

**Answer:**
They collaborate closely via YARN through the following steps:
1. The client submits the MapReduce job to the **ResourceManager**.
2. The ResourceManager launches the **Application Master** in a first container.
3. The Application Master analyzes the data volume and asks the ResourceManager to allocate additional containers (CPU and memory) on the cluster nodes.
4. It then commands the execution of **Map** tasks and coordinates the **Reduce** tasks of the MapReduce code.
5. Finally, it monitors progress, handles any task failures, and notifies when the job is finished.

---

### Q13 - What if the application master goes down or worker tasks fail?

**Answer:** 
* The application master monitors worker tasks for errors or hanging, and restarts them as needed (preferably on a different node).
* If the application master itself goes down, YARN can try to restart it.

---

### Q14 - What if an entire Node goes down?

**Answer:** 
* If an entire node goes down (which could be running the application master), the resource manager will try to restart it.

---

### Q15 - What if the resource manager goes down?

**Answer:** 
* You can set up "high availability" (HA) using Zookeeper to have a hot standby.


```