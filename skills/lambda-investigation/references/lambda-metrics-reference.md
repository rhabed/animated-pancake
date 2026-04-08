# Lambda CloudWatch Metrics Reference

## Invocation Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| Errors | < 1% of Invocations | > 5% of Invocations | > 10% of Invocations |
| Throttles | 0 | > 0 sustained | > 1% of Invocations |
| Duration (p99) | < 50% of timeout | > 70% of timeout | > 90% of timeout |
| Duration (max) | < 80% of timeout | > 90% of timeout | = timeout (timed out) |
| InitDuration (p99) | < 1s (scripting), < 5s (JVM) | > 3s (scripting), > 8s (JVM) | > 5s (scripting), > 10s (JVM) |
| ConcurrentExecutions | < 80% of limit | > 80% of limit | > 95% of limit |
| IteratorAge | < 1 minute | > 5 minutes | > 1 hour |
| DestinationDeliveryFailures | 0 | > 0 | Sustained > 0 |

## Memory Configuration Guidelines

| Memory (MB) | CPU Share | Typical Use Case |
|------------|-----------|-----------------|
| 128 | 1/8 vCPU | Simple transforms, small payloads |
| 256 | 1/4 vCPU | Basic API handlers, S3 event processing |
| 512 | 1/2 vCPU | Moderate processing, SDK calls |
| 1024 | ~1 vCPU | Data processing, image manipulation |
| 1769 | 1 full vCPU | Compute-intensive tasks |
| 3008 | ~2 vCPU | Heavy processing, ML inference |
| 10240 | 6 vCPU | Maximum compute, large data processing |

Memory exhaustion indicators:
- `Runtime.ExitError` with SIGKILL in logs
- `Max Memory Used` in REPORT line equals configured memory
- Process killed without stack trace

## Timeout Reference

| Trigger Type | Default Timeout | Max Timeout | Recommended |
|-------------|----------------|-------------|-------------|
| API Gateway (sync) | 3s | 29s (API GW limit) | < 10s |
| SQS | 3s | 900s (15 min) | < visibility timeout |
| EventBridge | 3s | 900s (15 min) | Based on workload |
| S3 event | 3s | 900s (15 min) | Based on object size |
| Scheduled (cron) | 3s | 900s (15 min) | Based on workload |
| Step Functions | 3s | 900s (15 min) | Based on task |

## Concurrency Limits

| Limit Type | Default | Adjustable | Notes |
|-----------|---------|-----------|-------|
| Account concurrent executions | 1000 | Yes (Service Quotas) | Shared across all functions |
| Burst concurrency | 500-3000 | No | Region-dependent |
| Scale rate (after burst) | 500/min | No | Linear scaling |
| Reserved concurrency (per function) | None | Yes | Both floor and ceiling |
| Provisioned concurrency | None | Yes | Eliminates cold starts |

## Event Source Scaling Behavior

| Event Source | Concurrency Model | Scaling Rate | Max Concurrency |
|-------------|-------------------|-------------|----------------|
| API Gateway | 1 invocation per request | Immediate | Account limit |
| SQS (standard) | Batch-based polling | 60 instances/min (up to 1000) | 1000 batches |
| SQS (FIFO) | Per message group | Limited by groups | Up to function concurrency |
| Kinesis | Per shard | Parallelization factor | Shards × parallelization factor |
| DynamoDB Streams | Per shard | Parallelization factor | Shards × parallelization factor |
| EventBridge | 1 invocation per event | Immediate | Account limit |
| S3 | 1 invocation per event | Immediate | Account limit |
| SNS | 1 invocation per message | Immediate | Account limit |

## Common Error Codes

| Error | Cause | Resolution |
|-------|-------|-----------|
| `Runtime.HandlerNotFound` | Handler path incorrect | Verify handler setting matches file and function name |
| `Runtime.ImportModuleError` | Missing dependency | Check deployment package includes all dependencies |
| `Runtime.ExitError` (SIGKILL) | Out of memory | Increase memory configuration |
| `Runtime.ExitError` (SIGSEGV) | Native library crash | Check native dependency compatibility |
| `Task timed out` | Execution exceeded timeout | Increase timeout or optimize function |
| `RequestEntityTooLarge` | Payload > 6 MB (sync) or > 256 KB (async) | Reduce payload or use S3 reference |
| `TooManyRequestsException` | Throttled | Increase concurrency limits or add retries |
| `ResourceNotFoundException` | Function/alias/version not found | Verify function exists and ARN is correct |
| `InvalidParameterValueException` | Bad configuration | Check memory, timeout, and runtime settings |
| `KMSAccessDeniedException` | Cannot decrypt env vars | Check KMS key policy for Lambda role |

## VPC-Attached Lambda Considerations

| Factor | Impact | Mitigation |
|--------|--------|-----------|
| Cold start overhead | +1-2s (Hyperplane ENI) | Provisioned concurrency |
| Subnet IP exhaustion | Functions fail to initialize | Use larger subnets, monitor available IPs |
| NAT gateway required | For internet access | VPC endpoints for AWS services |
| DNS resolution | Can add latency | Verify VPC DNS settings |
| Security groups | Outbound rules must allow traffic | Allow required ports to downstream services |
| Cross-AZ data transfer | Cost for multi-AZ subnets | Acceptable for HA, monitor costs |

## Lambda Power Tuning Reference

Optimal memory settings by workload type:

| Workload Type | Memory Sweet Spot | CPU Benefit Threshold |
|--------------|------------------|--------------------|
| I/O bound (API calls, DB) | 256-512 MB | Minimal above 512 MB |
| CPU bound (data processing) | 1769 MB (1 vCPU) | Linear up to 1769 MB |
| Mixed I/O + CPU | 512-1024 MB | Depends on ratio |
| Memory bound (large payloads) | Match payload size + overhead | N/A |
