# RDS CloudWatch Metrics Reference

## Connection Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| DatabaseConnections | < 70% of max_connections | > 80% of max_connections | > 90% of max_connections |

### Default max_connections by Instance Class

| Instance Class | MySQL Default | PostgreSQL Default |
|---------------|--------------|-------------------|
| db.t3.micro | 66 | 112 |
| db.t3.small | 150 | 225 |
| db.t3.medium | 312 | 450 |
| db.r5.large | 1365 | 1600 |
| db.r5.xlarge | 2730 | 3200 |
| db.r5.2xlarge | 5461 | 5000 |
| db.r5.4xlarge | 10922 | 5000 |

Formula: MySQL: `{DBInstanceClassMemory/12582880}`, PostgreSQL: `LEAST({DBInstanceClassMemory/9531392}, 5000)`

## Performance Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| ReadLatency | < 5ms | > 10ms | > 20ms |
| WriteLatency | < 5ms | > 10ms | > 20ms |
| DiskQueueDepth | < 1 | > 2 sustained | > 5 sustained |
| ReadIOPS | < 80% provisioned | > 80% provisioned | > 95% provisioned |
| WriteIOPS | < 80% provisioned | > 80% provisioned | > 95% provisioned |

## Compute Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| CPUUtilization | < 70% | > 80% sustained 10m | > 95% sustained 5m |
| FreeableMemory | > 25% of instance memory | < 15% of instance memory | < 5% of instance memory |
| SwapUsage | 0 MB | > 50 MB | > 256 MB |

## Storage Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| FreeStorageSpace | > 30% of allocated | < 20% of allocated | < 10% of allocated |
| FreeLocalStorage (Aurora) | > 5 GB | < 3 GB | < 1 GB |
| VolumeBytesUsed (Aurora) | < 80% of limit | > 80% of limit | > 90% of limit |

## Replication Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| ReplicaLag | < 5 seconds | > 30 seconds | > 120 seconds |
| OldestReplicationSlotLag (PG) | < 100 MB | > 500 MB | > 1 GB |
| TransactionLogsDiskUsage (PG) | < 2 GB | > 5 GB | > 10 GB |

## Storage Type IOPS Reference

| Storage Type | Baseline IOPS | Max IOPS | Baseline Throughput | Max Throughput |
|-------------|--------------|----------|--------------------|--------------|
| gp2 (< 1TB) | 3 IOPS/GiB (min 100) | 16,000 | 128 MiB/s | 250 MiB/s |
| gp3 | 3,000 | 16,000 | 125 MiB/s | 1,000 MiB/s |
| io1 | Provisioned | 64,000 | Provisioned | 1,000 MiB/s |
| io2 | Provisioned | 256,000 | Provisioned | 4,000 MiB/s |

## Aurora-Specific Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| AuroraReplicaLag | < 20ms | > 50ms | > 100ms |
| AuroraBinlogReplicaLag | < 30 seconds | > 120 seconds | > 300 seconds |
| BufferCacheHitRatio | > 95% | < 90% | < 80% |
| Deadlocks | 0 | > 1/min | > 5/min |
| LoginFailures | 0 | > 5/min | > 20/min |

## Key Engine Parameters to Check

### PostgreSQL
| Parameter | Purpose | Common Issue |
|-----------|---------|-------------|
| shared_buffers | Memory for caching | Too low → excessive disk reads |
| work_mem | Memory per sort/hash | Too low → sort spills to disk |
| effective_cache_size | Planner's cache estimate | Affects query plan choices |
| max_wal_size | WAL file retention | Too low → frequent checkpoints |
| log_min_duration_statement | Slow query logging | Set to capture slow queries |

### MySQL
| Parameter | Purpose | Common Issue |
|-----------|---------|-------------|
| innodb_buffer_pool_size | InnoDB cache | Too low → excessive disk I/O |
| innodb_log_file_size | Redo log size | Too small → frequent flushing |
| max_connections | Connection limit | Too low → connection refused |
| long_query_time | Slow query threshold | Set to capture slow queries |
| innodb_flush_log_at_trx_commit | Durability setting | 1 = safe, 2 = faster |
