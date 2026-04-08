---
name: ec2-investigation
description: Investigation procedures for EC2 instance issues including instance health checks, status check failures, connectivity problems, CPU and memory pressure, EBS volume performance, and capacity errors. Use this skill when investigating EC2 instance unreachability, degraded performance, launch failures, or status check alarms.
---

# EC2 Instance Investigation

Use this skill when operators report EC2 instance issues such as unreachable instances, degraded performance, failed status checks, launch failures, or unexpected terminations.

## Step 1: Identify the affected instance

Determine the instance ID, region, and account. Query the instance state and confirm whether the instance is running, stopped, terminated, or pending.

Retrieve basic instance metadata:
- Instance type, AMI, launch time
- VPC, subnet, availability zone
- IAM instance profile
- Key pair name

## Step 2: Check instance status checks

Query EC2 status checks for the affected instance:

- **System status check**: Detects problems with the underlying host. Failures indicate AWS infrastructure issues (loss of network connectivity, system power, hardware/software on the physical host).
- **Instance status check**: Detects problems that require instance owner involvement. Failures indicate issues such as exhausted memory, corrupted filesystem, incompatible kernel, or misconfigured networking.

If system status check fails:
1. Check AWS Health Dashboard for ongoing events in the availability zone
2. Consider stopping and starting the instance (migrates to new host)
3. If persistent, check if the instance is on dedicated hardware

If instance status check fails:
1. Review the system log (`GetConsoleOutput`) for boot errors or kernel panics
2. Check if the instance has run out of memory (OOM killer activity)
3. Check for filesystem corruption messages
4. Verify networking configuration (routes, DNS, NTP)

## Step 3: Analyze CloudWatch metrics

Retrieve the following CloudWatch metrics for the past 1-6 hours depending on issue duration:

**CPU and compute:**
- `CPUUtilization` — sustained above 90% indicates CPU pressure
- `CPUCreditBalance` (burstable instances only) — zero balance means throttling
- `CPUSurplusCreditBalance` — nonzero indicates surplus credit usage

**Network:**
- `NetworkIn` / `NetworkOut` — sudden drops indicate connectivity loss
- `NetworkPacketsIn` / `NetworkPacketsOut` — zero packets confirms network failure

**Disk:**
- `EBSReadOps` / `EBSWriteOps` — high values with latency indicate I/O bottleneck
- `EBSReadBytes` / `EBSWriteBytes` — throughput saturation check
- `EBSIOBalance%` / `EBSByteBalance%` — zero means volume burst credits exhausted

**Status:**
- `StatusCheckFailed` — combined check (0 = healthy, 1 = failed)
- `StatusCheckFailed_System` — system check specifically
- `StatusCheckFailed_Instance` — instance check specifically

See [ec2-metrics-reference.md](references/ec2-metrics-reference.md) for full metric thresholds.

## Step 4: Investigate connectivity issues

If the instance is running but unreachable:

1. **Security groups**: Verify inbound rules allow traffic on the required ports from the source CIDR
2. **Network ACLs**: Check both inbound and outbound rules on the subnet (NACLs are stateless)
3. **Route tables**: Verify the subnet route table has appropriate routes (internet gateway, NAT gateway, VPC peering, transit gateway)
4. **Elastic IP / Public IP**: Confirm the instance has a public IP if external access is required
5. **DNS resolution**: Verify VPC DNS settings (enableDnsSupport and enableDnsHostnames)
6. **VPC Flow Logs**: Check for REJECT entries matching the traffic pattern

Decision tree for connectivity:
- Can reach other instances in same subnet? → Check security group and instance-level firewall
- Cannot reach any instance in subnet? → Check NACL and route table
- Can reach from within VPC but not externally? → Check internet gateway, NAT, and public IP
- Intermittent connectivity? → Check network throughput limits for instance type

## Step 5: Investigate performance degradation

If the instance is reachable but slow:

1. **CPU throttling** (burstable instances T2/T3/T3a):
   - Check `CPUCreditBalance` — if zero, the instance is limited to baseline performance
   - Consider switching to unlimited mode or upsizing the instance type

2. **Memory pressure**:
   - If CloudWatch Agent is installed, check `mem_used_percent` custom metric
   - If not, review system log for OOM killer messages
   - Check swap usage if available

3. **EBS volume performance**:
   - Check `VolumeQueueLength` — sustained above 1 indicates I/O saturation
   - Check `VolumeReadLatency` / `VolumeWriteLatency` — above 10ms for gp3, above 1ms for io2 indicates degradation
   - Verify volume type matches workload (gp3 vs io2 vs st1)
   - Check if volume IOPS/throughput limits are being hit

4. **Network throughput**:
   - Compare `NetworkIn`/`NetworkOut` against instance type network bandwidth limits
   - Check for packet loss patterns in flow logs
   - Verify enhanced networking (ENA) is enabled

## Step 6: Investigate launch failures

If instances fail to launch:

1. **Insufficient capacity**: Check if the AZ has capacity for the instance type. Try launching in a different AZ.
2. **Instance limit**: Verify the account hasn't reached the vCPU limit for the instance family (Service Quotas).
3. **AMI issues**: Confirm the AMI exists and is available in the target region. Check if it's a shared AMI that was deregistered.
4. **Subnet IP exhaustion**: Check available IP addresses in the target subnet.
5. **IAM permissions**: Verify the caller has `ec2:RunInstances` and associated permissions.
6. **EBS encryption**: If default EBS encryption is enabled, verify KMS key permissions.

## Step 7: Summarize findings

Provide a summary with:
1. Instance identification (ID, type, AZ, account)
2. Current status and health check results
3. Root cause hypothesis with supporting metrics and evidence
4. Impact assessment (affected services, duration)
5. Recommended remediation steps ranked by priority
6. Preventive measures to avoid recurrence
