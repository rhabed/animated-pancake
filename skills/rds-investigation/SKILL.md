---
name: rds-investigation
description: Investigation procedures for RDS database issues including connection exhaustion, slow queries, replication lag, storage capacity, failover events, and Multi-AZ health. Use this skill when investigating database latency, connection errors, read/write performance degradation, replica lag, or RDS event notifications.
---

# RDS Database Investigation

Use this skill when operators report database issues such as connection failures, query timeouts, high latency, replication lag, storage alerts, or unexpected failovers.

## Step 1: Identify the affected instance

Determine the DB instance identifier, engine type (MySQL, PostgreSQL, Aurora, etc.), region, and account. Query the instance status and confirm whether it is available, backing-up, modifying, failed, or in maintenance.

Retrieve basic instance metadata:
- DB instance class, engine version
- Multi-AZ deployment status
- VPC, subnet group, availability zone
- Storage type (gp3, io2, aurora), allocated storage
- Parameter group, option group
- Automated backup retention, maintenance window

## Step 2: Check recent RDS events

Query RDS events for the past 24 hours for the affected instance. Look for:
- Failover events (Multi-AZ switchover)
- Maintenance events (patching, hardware maintenance)
- Configuration changes (parameter group, instance class modifications)
- Storage autoscaling events
- Backup-related events
- Recovery events

Correlate event timestamps with the reported issue start time.

## Step 3: Analyze CloudWatch metrics

Retrieve the following CloudWatch metrics for the past 1-6 hours:

**Connections:**
- `DatabaseConnections` — compare against `max_connections` parameter
- Connection count near limit indicates pool exhaustion or connection leaks

**Performance:**
- `ReadLatency` / `WriteLatency` — baseline is typically < 5ms
- `ReadIOPS` / `WriteIOPS` — compare against provisioned or burst IOPS limits
- `ReadThroughput` / `WriteThroughput` — check for throughput saturation
- `DiskQueueDepth` — sustained above 1 indicates I/O bottleneck

**CPU and memory:**
- `CPUUtilization` — sustained above 85% indicates compute pressure
- `FreeableMemory` — low values indicate memory pressure and increased swap
- `SwapUsage` — nonzero indicates memory pressure (critical for performance)

**Storage:**
- `FreeStorageSpace` — below 20% requires immediate attention
- `FreeLocalStorage` (Aurora) — local storage for temp tables
- `VolumeBytesUsed` (Aurora) — cluster volume usage

**Replication (read replicas):**
- `ReplicaLag` — above 30 seconds indicates replication falling behind
- `OldestReplicationSlotLag` (PostgreSQL) — lag in logical replication slots
- `TransactionLogsDiskUsage` (PostgreSQL) — WAL accumulation from lag

See [rds-metrics-reference.md](references/rds-metrics-reference.md) for full metric thresholds by engine.

## Step 4: Investigate connection issues

If applications cannot connect or connections are being refused:

1. **Connection count at limit**:
   - Check `DatabaseConnections` against `max_connections` (engine parameter)
   - Identify clients holding connections: query `pg_stat_activity` (PostgreSQL) or `SHOW PROCESSLIST` (MySQL)
   - Look for idle connections that should be returned to the pool
   - Check application connection pool settings (min/max pool size, idle timeout)

2. **Security group / network**:
   - Verify the DB security group allows inbound traffic on the database port from the application subnets
   - Check NACLs on the DB subnet
   - Verify DNS resolution of the DB endpoint from the application
   - For private endpoints, confirm VPC routing

3. **Authentication failures**:
   - Check for IAM authentication token expiry (15-minute lifetime)
   - Verify master credentials haven't been rotated
   - Check SSL/TLS certificate validity if enforced

4. **Failover impact**:
   - After Multi-AZ failover, DNS propagation takes 30-120 seconds
   - Applications using cached DNS may connect to the old endpoint
   - Check if application handles DNS TTL correctly

## Step 5: Investigate query performance

If the database is reachable but queries are slow:

1. **Enable Performance Insights** (if available):
   - Retrieve top SQL by average active sessions using `pi:GetResourceMetrics`
   - Identify wait events: CPU waits, I/O waits, lock waits
   - Check for top SQL changes correlating with issue onset

2. **Common slow query causes**:
   - Missing indexes: high `Rows_examined` vs `Rows_sent` ratio
   - Table locks: long-running transactions blocking others
   - Full table scans on large tables
   - Suboptimal query plans after statistics changes

3. **Parameter group investigation**:
   - Check `work_mem` / `sort_buffer_size` for sort spills to disk
   - Check `shared_buffers` / `innodb_buffer_pool_size` for cache hit ratio
   - Check `effective_cache_size` / `innodb_buffer_pool_instances`
   - Verify `log_min_duration_statement` (PostgreSQL) or `long_query_time` (MySQL) captures slow queries

4. **Storage IOPS saturation**:
   - Compare current IOPS against provisioned limits
   - gp3 baseline: 3000 IOPS, burstable to provisioned
   - io2: consistent provisioned IOPS
   - If IOPS limited, consider upgrading storage type or provisioned IOPS

## Step 6: Investigate replication lag

If read replicas are lagging:

1. **Check replica lag metric trend**: is lag increasing, stable, or recovering?
2. **Write-heavy primary**: high write volume on primary exceeds replica apply rate
3. **Replica compute**: replica instance class too small to keep up with apply rate
4. **Long-running queries on replica**: can block replication apply
5. **Network throughput**: cross-region replicas limited by network bandwidth
6. **PostgreSQL-specific**: check `max_standby_streaming_delay` parameter
7. **MySQL-specific**: check if parallel replication is enabled (`slave_parallel_workers`)

## Step 7: Investigate storage issues

If storage alerts are firing:

1. **FreeStorageSpace declining**:
   - Check if storage autoscaling is enabled and has headroom
   - Identify large tables or indexes consuming space
   - Check for bloat (PostgreSQL: `pg_stat_user_tables` dead tuples, MySQL: fragmentation)
   - Verify binary log / WAL retention settings

2. **Temporary storage** (Aurora `FreeLocalStorage`):
   - Large sort operations spilling to disk
   - Temporary tables from complex queries
   - Reduce query complexity or increase instance class

## Step 8: Summarize findings

Provide a summary with:
1. Database identification (instance ID, engine, version, instance class)
2. Current status and health indicators
3. Root cause hypothesis with supporting metrics and evidence
4. Impact assessment (affected applications, query types, duration)
5. Recommended remediation steps ranked by priority
6. Preventive measures (monitoring thresholds, parameter tuning, scaling)
