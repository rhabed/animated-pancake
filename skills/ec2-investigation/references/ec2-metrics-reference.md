# EC2 CloudWatch Metrics Reference

## Instance Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| CPUUtilization | < 70% | > 80% sustained 10m | > 95% sustained 5m |
| CPUCreditBalance (T-series) | > 50% of max | < 20% of max | 0 (throttled) |
| CPUSurplusCreditBalance | 0 | > 0 (spending) | Growing (unsustainable) |
| NetworkIn | Varies by type | > 80% of type limit | > 95% of type limit |
| NetworkOut | Varies by type | > 80% of type limit | > 95% of type limit |
| NetworkPacketsIn | > 0 | Sudden drop > 50% | 0 (no traffic) |
| NetworkPacketsOut | > 0 | Sudden drop > 50% | 0 (no traffic) |
| StatusCheckFailed | 0 | - | 1 (failed) |
| StatusCheckFailed_System | 0 | - | 1 (failed) |
| StatusCheckFailed_Instance | 0 | - | 1 (failed) |

## EBS Volume Metrics

| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| VolumeQueueLength | < 1 | > 2 sustained | > 4 sustained |
| VolumeReadLatency | < 1ms (io2), < 5ms (gp3) | > 5ms (io2), > 10ms (gp3) | > 20ms |
| VolumeWriteLatency | < 1ms (io2), < 5ms (gp3) | > 5ms (io2), > 10ms (gp3) | > 20ms |
| EBSIOBalance% | > 50% | < 30% | 0% (burst exhausted) |
| EBSByteBalance% | > 50% | < 30% | 0% (burst exhausted) |
| VolumeThroughputPercentage | < 70% | > 80% | > 95% |

## Instance Type Network Bandwidth Reference

| Instance Family | Example | Baseline Bandwidth | Burst Bandwidth |
|----------------|---------|-------------------|----------------|
| t3.micro | t3.micro | Up to 5 Gbps | 5 Gbps |
| t3.large | t3.large | Up to 5 Gbps | 5 Gbps |
| m5.large | m5.large | Up to 10 Gbps | 10 Gbps |
| m5.xlarge | m5.xlarge | Up to 10 Gbps | 10 Gbps |
| c5.2xlarge | c5.2xlarge | Up to 10 Gbps | 10 Gbps |
| m5.4xlarge | m5.4xlarge | Up to 10 Gbps | 10 Gbps |
| r5.8xlarge | r5.8xlarge | 10 Gbps | 10 Gbps |
| m5.24xlarge | m5.24xlarge | 25 Gbps | 25 Gbps |

## Burstable Instance CPU Credit Reference

| Instance Type | Baseline CPU % | Max Credits | Credits/Hour |
|--------------|---------------|-------------|-------------|
| t3.nano | 5% | 144 | 6 |
| t3.micro | 10% | 288 | 12 |
| t3.small | 20% | 576 | 24 |
| t3.medium | 20% | 576 | 24 |
| t3.large | 30% | 864 | 36 |
| t3.xlarge | 40% | 2304 | 96 |
| t3.2xlarge | 40% | 4608 | 192 |

## Common CloudWatch Agent Custom Metrics

When the CloudWatch Agent is installed, these additional metrics may be available:

| Metric | Namespace | Normal Range | Critical Threshold |
|--------|-----------|-------------|-------------------|
| mem_used_percent | CWAgent | < 80% | > 95% |
| disk_used_percent | CWAgent | < 80% | > 90% |
| swap_used_percent | CWAgent | < 20% | > 80% |
| netstat_tcp_established | CWAgent | Varies | Sudden spike/drop |
| processes_total | CWAgent | Varies | > 500 (investigate) |
