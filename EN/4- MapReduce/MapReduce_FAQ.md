## ❓ Frequently Asked Questions (FAQ) - Hadoop MapReduce

Here you will find answers to the most frequently asked questions by students regarding the execution and debugging of MapReduce jobs.

---

### 1. What is the difference between a `Mapper` and a `Reducer`?
* **Mapper:** Processes input data in parallel, block by block (or line by line). Its role is to analyze raw data and emit intermediate **key-value pairs** using the `context.write(key, value)` method.
* **Reducer:** Receives all grouped and sorted values associated with a **single unique key** (originating from the Mappers after the *Shuffle and Sort* phase). It then performs an aggregation operation (sum, average, maximum, etc.) to produce the final result.

---

### 2. What is the *Shuffle and Sort* phase and why is it critical?
The *Shuffle and Sort* is the automatic intermediate phase managed by the Hadoop framework between the end of the Mappers and the start of the Reducers:
* **Shuffle:** The output data from the Mappers is collected, transferred, and redistributed across the network so that all values for the same key are sent to the same Reducer.
* **Sort:** Keys are automatically sorted in ascending order before being passed to the Reducer.
* **Impact:** This is often the main performance **bottleneck** because it generates a large amount of network traffic. Good key design helps minimize this overhead.

---

### 3. Why is my MapReduce job stuck at 0% or 99%?
* **Stuck at 0% (at launch):** 
  * Check that your YARN daemons (ResourceManager and NodeManagers) and HDFS (NameNode and DataNodes) are active in your Docker cluster.
  * Ensure that the input file path specified in your `hadoop jar` command actually exists in HDFS (`hdfs dfs -ls /path`).
* **Stuck at 99% (near completion):** 
  * This is classic behavior. The job has finished all its Mappers and Reducers, but it is cleaning up temporary files, validating blocks, or writing final results. Please wait a few moments.

---

### 4. How can I debug a failed job without a clear error message?
* **Check YARN application logs:** Use the following command in your containerized terminal to display the error history of the latest application:
  ```bash
  yarn logs -applicationId <application_id>