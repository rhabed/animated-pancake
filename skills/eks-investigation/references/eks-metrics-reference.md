# EKS CloudWatch Metrics Reference

## Container Insights Cluster Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| cluster_failed_node_count | 0 | > 0 | > 1 |
| cluster_node_count | Matches expected | < expected | Significant drop |
| node_cpu_utilization | < 70% | > 80% | > 95% |
| node_memory_utilization | < 75% | > 85% | > 95% |
| node_filesystem_utilization | < 70% | > 80% | > 90% |
| node_network_total_bytes | Varies | > 80% of type limit | > 95% of type limit |

## Container Insights Pod Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| pod_cpu_utilization | < 70% of request | > 80% of limit | > 95% of limit |
| pod_memory_utilization | < 75% of request | > 85% of limit | > 95% of limit (OOM risk) |
| pod_number_of_container_restarts | 0 | > 3 in 1h | > 10 in 1h (CrashLoopBackOff) |
| pod_status (Running) | All expected pods | Missing pods | Significant pod loss |

## EKS Control Plane Metrics (via CloudWatch Logs Insights)

| Log Pattern | Indicates | Severity |
|------------|-----------|----------|
| `responseStatus.code >= 500` | API server errors | Critical |
| `responseStatus.code = 429` | API throttling | Warning |
| `responseStatus.code = 401/403` | Auth failures | Warning |
| `verb=create resource=pods reason=FailedScheduling` | Scheduling failures | Warning |
| `Failed to pull image` | Image pull errors | Warning |
| `OOMKilled` | Memory limit exceeded | Critical |
| `NodeNotReady` | Node health issues | Critical |

## Max Pods Per Node (Common Instance Types)

The maximum pods per node is determined by: (ENIs × (IPs per ENI - 1)) + 2

| Instance Type | Max ENIs | IPs per ENI | Max Pods (default) | Max Pods (prefix delegation) |
|--------------|----------|-------------|--------------------|-----------------------------|
| t3.micro | 2 | 2 | 4 | 4 |
| t3.small | 3 | 4 | 11 | 35 |
| t3.medium | 3 | 6 | 17 | 47 |
| t3.large | 3 | 12 | 35 | 110 |
| m5.large | 3 | 10 | 29 | 110 |
| m5.xlarge | 4 | 15 | 58 | 110 |
| m5.2xlarge | 4 | 15 | 58 | 110 |
| m5.4xlarge | 8 | 30 | 234 | 250 |
| c5.2xlarge | 4 | 15 | 58 | 110 |
| r5.xlarge | 4 | 15 | 58 | 110 |
| m5.24xlarge | 15 | 50 | 737 | 737 |

## VPC CNI Plugin Configuration

| Setting | Default | Purpose | Impact |
|---------|---------|---------|--------|
| WARM_ENI_TARGET | 1 | ENIs to keep pre-allocated | Higher = faster pod startup, more IPs consumed |
| WARM_IP_TARGET | unset | IPs to keep warm per node | More granular than ENI target |
| MINIMUM_IP_TARGET | unset | Minimum warm IPs | Floor for IP pre-allocation |
| ENABLE_PREFIX_DELEGATION | false | Assign /28 prefixes instead of individual IPs | Significantly increases max pods per node |
| AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG | false | Use custom networking for pods | Pods use different subnets than nodes |

## CoreDNS Health Indicators

| Check | Healthy State | Degraded State |
|-------|--------------|----------------|
| Pod count | Matches desired (usually 2+) | Below desired |
| Pod status | All Running | CrashLoopBackOff, Pending |
| CPU usage | < 50% of limit | > 80% of limit |
| Memory usage | < 60% of limit | > 80% of limit |
| DNS response latency | < 5ms intra-cluster | > 100ms |
| NXDOMAIN rate | Low and stable | Spike (misconfigured services) |
| SERVFAIL rate | 0 | > 0 (upstream DNS issues) |

## Common EKS Add-on Versions Compatibility

| Kubernetes Version | Recommended VPC CNI | Recommended CoreDNS | Recommended kube-proxy |
|-------------------|--------------------|--------------------|----------------------|
| 1.28 | v1.16.x | v1.10.1 | v1.28.x |
| 1.29 | v1.17.x | v1.11.1 | v1.29.x |
| 1.30 | v1.18.x | v1.11.3 | v1.30.x |
| 1.31 | v1.19.x | v1.12.x | v1.31.x |

## Node Condition Reference

| Condition | Meaning | Common Cause |
|-----------|---------|-------------|
| Ready=True | Node is healthy | Normal state |
| Ready=False | Node is unhealthy | kubelet issue, container runtime, network |
| Ready=Unknown | Node lost contact | Network partition, node crash |
| MemoryPressure | Node approaching memory limit | Pod memory usage too high |
| DiskPressure | Node disk usage high | Container images, logs, emptyDir volumes |
| PIDPressure | Too many processes | Fork bombs, process leaks |
| NetworkUnavailable | CNI not configured | VPC CNI plugin not running |
