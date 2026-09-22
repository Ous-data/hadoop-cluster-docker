# 📚 FAQ - HDFS & Hadoop Course

This document gathers frequently asked questions and answers for the Hadoop ecosystem and HDFS distributed file system course.

---

### Q1 - How is the Standby NameNode synchronized with the Active NameNode?

**Answer:** 
The Standby NameNode (SNN) keeps its state synchronized with the Active NameNode primarily through **JournalNodes (JNs)** or a shared storage:
* **Logging modifications:** The Active NameNode records every modification to the namespace (transactions) into an edit log called *EditLog*. Every write is immediately sent via *streaming* to the JournalNodes.
* **Continuous reading:** The Standby NameNode continuously reads these edit logs from the JournalNodes and applies the changes to its own memory to maintain an exact and up-to-date image of the file system.
* **Block reports:** DataNodes send their *Heartbeats* and *Blockreports* simultaneously to both NameNodes (Active and Standby) so that the Standby knows the exact location of the data blocks.

---

### Q2 - What is the difference between a Secondary NameNode and a Standby NameNode?

**Answer:** 
Although both roles prevent data loss, their functions are completely different:
* **Secondary NameNode:** It is **not** a failover standby node (*no High Availability*). Its sole role is to lighten the load on the Active NameNode by periodically merging the file system image (`FSImage`) and the transaction log (`EditLog`) to prevent the log from growing too large.
* **Standby NameNode:** It is a *Hot Standby* node in a High Availability (HA) architecture. It keeps an exact copy of the NameNode state in memory and is ready to *Failover* instantly to take over if the Active NameNode goes down.

---

### Q3 - How are Heartbeats implemented—like a ping, or small TCP packets?

**Answer:** 
Heartbeats are not simple Layer 3 ICMP pings, but rather **Remote Procedure Calls (RPCs) encapsulated within application-level TCP connections**:
* They are sent periodically (every 3 seconds by default) by each DataNode to the NameNode.
* In addition to signaling that the DataNode is alive, these messages carry essential metadata such as total storage capacity, available disk space, and the number of ongoing transfers.
* If the NameNode stops receiving heartbeats from a DataNode beyond a safety timeout threshold, it considers the node dead and triggers the replication of lost blocks.

---

### Q4 - How does communication between nodes take place: via TCP, IP address, or DNS?

**Answer:** 
Communication within the Hadoop cluster relies on a combination of these technologies:
* **TCP and IP Addresses:** All data transmissions (between clients and DataNodes, or between DataNodes during the replication pipeline) and RPC requests happen at the transport layer via **TCP** sockets connected to specific ports (e.g., port 8020 for the NameNode).
* **DNS and Hostnames:** Hadoop actively uses name resolution (**DNS** or the local `/etc/hosts` file) to identify and reference machines. Configuration files (`core-site.xml`, `hdfs-site.xml`, etc.) generally rely on hostnames to simplify cluster management.

---

### Q5 - When a file is transferred to HDFS, is it stored first on the NameNode?

**Answer:** 
**No, absolutely not.** The NameNode never stores the content of data files.
* **The role of the NameNode:** When a client wants to write a file, it first contacts the NameNode to get authorization and the list of target **DataNodes** where the file's blocks should be stored. The NameNode only manages metadata (directory tree, permissions, block locations).
* **Streaming transfer:** The file content (split into blocks) is then transmitted **directly from the client to the DataNodes** in **streaming** mode via TCP, following a replication pipeline from one DataNode to another. This prevents the NameNode from becoming a network bottleneck.

---

### Q6 - What is the exact role of the Secondary NameNode during checkpointing?

**Answer:** 
The Secondary NameNode regularly downloads the file system image (`FSImage`) and the active transaction log file (`EditLog`) from the Active NameNode. It combines them in its own memory to generate a new merged image file (`FSImage.ckpt`), which it then sends back to the Active NameNode. This reduces the size of the EditLog and speeds up the NameNode's next restart.

---

### Q7 - How do DataNodes communicate with each other when writing a large file in HDFS?

**Answer:** 
When writing a file, DataNodes communicate via a **replication pipeline** system:
* The client splits the file into blocks and sends the first block to the first DataNode over a TCP stream.
* As soon as this first DataNode receives the initial packets, it simultaneously forwards them to the second DataNode in the list, which in turn passes them to the third (depending on the configured replication factor, usually 3).
* This pipelined cascade transmission happens in real-time to optimize network bandwidth.

---

### Q8 - What happens if a DataNode abruptly stops while processing a task?

**Answer:** 
Hadoop's fault-tolerance mechanism reacts as follows:
* **Detection:** The NameNode notices the absence of *heartbeats* from the failing DataNode (exceeding the timeout limit).
* **Topology update:** The NameNode identifies all data blocks for which this node was the sole or one of the holders.
* **Backup replication:** The NameNode instructs other DataNodes holding healthy replicas to duplicate those blocks onto new operational nodes to restore the initial replication factor and ensure data safety.

---

### Q9 - What is Data Locality in the Hadoop ecosystem?

**Answer:** 
Data locality is a fundamental performance optimization principle consisting of **running computations (MapReduce or Spark tasks) on the exact same machine (DataNode) where the data to be processed is physically stored**. 
* This prevents saturating the corporate network by transferring heavy volumes of data from one server to another.
* The framework always prioritizes local processing (*node-local*), then rack-local, and only as a last resort via the external network.

---

### Q10 - Which Hadoop component manages resource allocation and task scheduling?

**Answer:** 
**YARN** (*Yet Another Resource Negotiator*) has managed this part since Hadoop 2.0:
* **ResourceManager (RM):** The global master component that arbitrates and allocates compute resources (CPU, memory) across the entire cluster.
* **NodeManager (NM):** The agent running on each worker node that monitors local resource usage and manages execution containers for assigned tasks.