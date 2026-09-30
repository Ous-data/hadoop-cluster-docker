
```markdown
# 📚 Practical Lab: HDFS Analysis, Blocks, and Resilience

## Objectives
* See how a file is split into blocks and distributed across the network[cite: 8].
* Test life signals (*Heartbeats*) and force an inventory (*Blockreports*)[cite: 8].
* Lock the cluster with *Safemode* and observe memory using `FsImage` + `EditLog`[cite: 8].

---

## Phase 1: Fundamental Architecture, Metadata, and Blocks

### Step 0: Prerequisites (Optional)
Start the `hadoop-master` container if it is not already running[cite: 8]:
```powershell
docker start hadoop-master

```

Start HDFS if it is not already running:

```bash
start-dfs.sh

```

Make sure DataNodes are started:

```bash
docker exec -it hadoop-worker1 bash
jps

```

If the `DataNode` does not appear in the list, start the service:

```bash
$HADOOP_HOME/sbin/hadoop-daemon.sh start datanode

```

>> Repeat the same procedure for `worker2`.

---

### Step 1: Create and Inject a Block-Split File

To observe splitting without saturating your machines, we force tiny blocks of **1 MB** (1,048,576 bytes).

1. Connect to the master container terminal:



```powershell
docker exec -it hadoop-master bash

```

2. Create a small text file of about 3 MB:



```bash
yes "Ceci est une ligne de test pour Hadoop" | head -n 80000 > /tmp/monfichier.txt

```

(This command generates text in a loop and keeps the first 80,000 lines).

3. Upload it to HDFS with 1 MB blocks:



```bash
hdfs dfs -Ddfs.blocksize=1048576 -put /tmp/monfichier.txt /monfichier.txt

```

---

### Step 2: Metadata Inspection with `fsck`

The NameNode knows the location of each piece without storing the file itself.

Ask the NameNode where the blocks are stored:

```bash
hdfs fsck /monfichier.txt -files -blocks -locations

```

> To note on your sheet:
> 
> 
> * How many blocks make up this file?
> 
> 
> * What is the identifier of the first block (e.g., `blk_...`)?
> 
> 
> * On which node (`worker1`, etc.) is this block located?
> 
> 
> 
> 

---

### Step 3: Discovering Physical Blocks on the DataNode

Real data is stored on the workers, not on the master!

1. Open a second PowerShell terminal and enter the worker container:



```powershell
docker exec -it hadoop-worker1 bash

```

2. Search for the block on the worker's hard drive:



```bash
find / -name "blk_*" 2>/dev/null

```

> **Finding:** You see your block as a simple Linux binary file, accompanied by a `.meta` file (which contains the checksum to verify it is not corrupted).
> 
> 

---

## Phase 2: Internal Mechanisms (*Heartbeats*, *Blockreports*, *Safemode*, *EditLog* & *FsImage*)

### Workshop 1: *Safemode*

*Safemode* is a safety lock: the system is read-only.

1. From `hadoop-master`, enable *Safemode* manually:



```bash
hdfs dfsadmin -safemode enter

```

2. Try to create a new folder:



```bash
hdfs dfs -mkdir /dossier_test

```

Finding: The operation fails with an error message indicating that the NameNode is in Safemode.

3. Try to read the existing file:



```bash
hdfs dfs -cat /monfichier.txt | head -n 5

```

Finding: Reading works! The mode protects data against modifications but allows consultation.

4. Exit *Safemode*:



```bash
hdfs dfsadmin -safemode leave

```

---

### Workshop 2: *Heartbeats*, Node Failure, and Replication

Workers send regular heartbeats to the master to prove they are working.

1. Display node status from `hadoop-master`:



```bash
hdfs dfsadmin -report

```

(Look at the `Last contact` line of `hadoop-worker1`: the number remains small thanks to regular Heartbeats).

2. Simulate a failure by shutting down the worker (from PowerShell):



```powershell
docker stop hadoop-worker1

```

3. Rerun the report on `hadoop-master` immediately:



```bash
hdfs dfsadmin -report

```

Finding: The `Last contact` counter grows. If the signal does not return, the NameNode will eventually declare the node "dead" and duplicate its data on other machines.

4. Restart the worker:



```powershell
docker start hadoop-worker1

```

---

### Workshop 3: Live *Blockreports*

The *Blockreport* is the inventory that the worker sends to the NameNode.

You can either wait 10 minutes and 30 seconds for `worker1` to be automatically declared inactive, or force `hadoop-worker1` to resend its inventory to the master (from `hadoop-master`):

```bash
hdfs dfsadmin -triggerBlockReport hadoop-worker1:9866

```

Observe the confirmation received by the NameNode:

```bash
hdfs dfsadmin -report

```

---

### Workshop 4: Persistent Metadata (`FsImage` + `EditLog`)

* **EditLog**: The logbook that immediately notes every action.


* **FsImage**: The global snapshot of the entire file system.



1. Create a new action in HDFS from `hadoop-master`:



```bash
hdfs dfs -touch /fichier_journal.txt

```

2. Check the files in the NameNode's system folder:



```bash
ls -la /root/hdfs/namenode/current/

```

Finding: You see `edits_inprogress_...` files and an `fsimage_...` file.

3. Force the creation of a new snapshot `FsImage` (clean backup):



```bash
hdfs dfsadmin -safemode enter
hdfs dfsadmin -saveNamespace
hdfs dfsadmin -safemode leave

```

---

## 📝 Validation Questions

* **Q1**: In Step 3, why is the binary file `blk_...` present on `hadoop-worker1` and not on `hadoop-master`?


* **Q2**: Why does the NameNode refuse writes in *Safemode* mode?


* **Q3**: What signal allows the NameNode to know if `hadoop-worker1` is still running?


* **Q4**: If the server restarts suddenly, what are the combined `FsImage` and `EditLog` files used for?



```

```