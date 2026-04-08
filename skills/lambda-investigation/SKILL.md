---
name: lambda-investigation
description: Investigation procedures for AWS Lambda function issues including invocation errors, cold starts, timeout failures, throttling, memory exhaustion, concurrency limits, and integration errors with API Gateway, SQS, EventBridge, and other event sources. Use this skill when investigating Lambda execution failures, high error rates, latency spikes, or throttled invocations.
---

# Lambda Function Investigation

Use this skill when operators report Lambda function issues such as invocation failures, high error rates, timeout errors, throttling, unexpected latency, or event source integration problems.

## Step 1: Identify the affected function

Determine the function name, region, account, and runtime. Query the function configuration and confirm its current state.

Retrieve function metadata:
- Runtime, handler, architecture (x86_64/arm64)
- Memory size, timeout, ephemeral storage
- VPC configuration (subnets, security groups) or non-VPC
- Execution role ARN
- Environment variables (check for missing or incorrect values)
- Layers and their versions
- Reserved concurrency or provisioned concurrency settings
- Dead letter queue or on-failure destination configuration
- Active versions and aliases in use

## Step 2: Check CloudWatch metrics

Retrieve the following CloudWatch metrics for the past 1-6 hours:

**Invocation health:**
- `Invocations` — total invocation count, compare against baseline
- `Errors` — function code errors (unhandled exceptions, non-zero exit codes)
- `Throttles` — invocations rejected due to concurrency limits
- `DestinationDeliveryFailures` — failures sending to on-failure destination

**Performance:**
- `Duration` (p50, p99, max) — execution time, compare against configured timeout
- `InitDuration` — cold start initialization time (first invocation after deployment or scaling)
- `PostRuntimeExtensionsDuration` — time spent in extensions after function response

**Concurrency:**
- `ConcurrentExecutions` — current concurrent executions
- `ProvisionedConcurrentExecutions` — provisioned concurrency in use
- `ProvisionedConcurrencySpilloverInvocations` — invocations exceeding provisioned concurrency
- `UnreservedConcurrentExecutions` — executions using unreserved account pool

**Iterator (stream-based sources):**
- `IteratorAge` — age of the last record processed from Kinesis/DynamoDB streams
- Increasing age means the function is falling behind the stream

See [lambda-metrics-reference.md](references/lambda-metrics-reference.md) for full metric thresholds.

## Step 3: Analyze CloudWatch Logs

Query the function's log group (`/aws/lambda/<function-name>`) for:

1. **Error patterns**: search for `ERROR`, `Task timed out`, `Runtime.ExitError`, `Runtime.HandlerNotFound`
2. **Out of memory**: search for `Runtime.ExitError` with signal `SIGKILL` or `Killed` — indicates memory exhaustion
3. **Timeout**: search for `Task timed out after X seconds` — function exceeded configured timeout
4. **Cold start indicators**: `INIT_START` log entries, correlate with InitDuration metric
5. **Import errors**: `Runtime.ImportModuleError` (Python), `Cannot find module` (Node.js)
6. **Permission errors**: `AccessDeniedException`, `is not authorized to perform`

Correlate error timestamps with the reported issue onset.

## Step 4: Investigate invocation errors

If the function is returning errors:

### Unhandled exceptions (Errors metric)
1. Check function logs for stack traces
2. Identify the error type:
   - Application logic errors (null references, type errors, assertion failures)
   - SDK errors (AWS service call failures, credential issues)
   - Dependency errors (external API timeouts, connection refused)
3. Check if errors started after a deployment (new version/alias)
4. Check environment variables for missing or changed values

### Timeout errors
1. Compare `Duration` p99 against configured timeout
2. Common causes:
   - Downstream service latency (database, API, S3)
   - VPC cold start adding 5-10 seconds (ENI creation)
   - Large payload processing
   - Connection pool exhaustion to external services
   - DNS resolution delays in VPC
3. If VPC-attached, check that NAT gateway and VPC endpoints are functioning
4. Check if timeout correlates with downstream service degradation

### Runtime crashes
1. `Runtime.ExitError` — process exited unexpectedly
2. Signal 9 (SIGKILL) — memory limit exceeded, Lambda runtime killed the process
3. Signal 11 (SIGSEGV) — segmentation fault, usually native library issue
4. Check if the function uses native dependencies compatible with the Lambda runtime

## Step 5: Investigate throttling

If invocations are being throttled:

1. **Account-level concurrency**:
   - Default account limit: 1000 concurrent executions (varies by region)
   - Check total `ConcurrentExecutions` across all functions
   - Request quota increase via Service Quotas if needed

2. **Function-level reserved concurrency**:
   - Check if the function has reserved concurrency set too low
   - Reserved concurrency acts as both a guarantee and a cap

3. **Provisioned concurrency**:
   - Check `ProvisionedConcurrencySpilloverInvocations` — nonzero means provisioned capacity exceeded
   - Consider increasing provisioned concurrency or adding auto-scaling

4. **Burst limit**:
   - Initial burst: 500-3000 concurrent executions (region-dependent)
   - After burst, scales by 500 additional instances per minute
   - Sudden traffic spikes can hit burst limit before scaling catches up

5. **Event source throttling**:
   - SQS: Lambda scales up to 1000 batches concurrently (5 batches/min increase)
   - Kinesis/DynamoDB Streams: parallelization factor × shard count
   - API Gateway: check for 429 responses from API Gateway itself

## Step 6: Investigate cold starts

If latency is higher than expected:

1. **Measure cold start frequency**: compare `Invocations` count vs `InitDuration` count
2. **Cold start contributors**:
   - Runtime initialization (JVM startup for Java can be 3-10 seconds)
   - VPC ENI attachment (if VPC-attached, can add 1-2 seconds with Hyperplane)
   - Layer loading (large layers increase init time)
   - Package size (larger deployment packages take longer to load)
   - Static initialization in handler code (database connections, SDK clients)

3. **Mitigation strategies**:
   - Provisioned concurrency eliminates cold starts for pre-warmed instances
   - SnapStart (Java) reduces cold start to < 200ms
   - Reduce deployment package size (exclude dev dependencies, use Lambda layers)
   - Move initialization outside the handler function
   - Use arm64 architecture (faster init for many runtimes)

## Step 7: Investigate event source integration issues

If events are not being processed:

### API Gateway
1. Check API Gateway CloudWatch metrics: `5XXError`, `IntegrationLatency`
2. Verify resource policy and IAM permissions
3. Check for payload size limits (6 MB synchronous, 256 KB for request/response)
4. Review API Gateway execution logs for integration errors

### SQS
1. Check SQS metrics: `ApproximateAgeOfOldestMessage`, `NumberOfMessagesNotVisible`
2. Verify Lambda event source mapping is enabled and not in error state
3. Check batch size and batch window configuration
4. Verify function can process within the SQS visibility timeout
5. Check dead letter queue for failed messages

### EventBridge
1. Check EventBridge metrics: `FailedInvocations`, `ThrottledRules`
2. Verify rule pattern matches incoming events
3. Check target input transformation configuration
4. Verify Lambda resource-based policy allows EventBridge invocation

### DynamoDB Streams / Kinesis
1. Check `IteratorAge` — increasing means falling behind
2. Verify shard count and parallelization factor
3. Check for `BisectBatchOnFunctionError` configuration
4. Review error handling: on-failure destination or maximum retry attempts

## Step 8: Summarize findings

Provide a summary with:
1. Function identification (name, runtime, memory, timeout, region, account)
2. Current invocation health (error rate, throttle rate, latency percentiles)
3. Root cause hypothesis with supporting metrics, logs, and evidence
4. Impact assessment (affected consumers, event backlog, duration)
5. Recommended remediation steps ranked by priority
6. Preventive measures (monitoring alarms, concurrency configuration, timeout tuning)
