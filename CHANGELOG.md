# Changelog

## 1.1.0

* **Performance**: Significantly improved CPU utilization in WorldCoverGenerator through advanced parallel processing architecture
* **Concurrency**: Eliminated mutex bottlenecks by redesigning tile processing with lock-free data structures and pipeline architecture
* **Architecture**: Separated world generation into independent stages: tile processing, object creation, and room connection phases
* **Scalability**: Increased default thread pool size to 2x CPU cores for better multi-core utilization
* **Optimization**: Implemented work-stealing queues and thread-local data structures to minimize contention
* **Threading**: Replaced single-threaded room creation with parallel processing threads for maximum efficiency

## 1.0.0

* Initial release