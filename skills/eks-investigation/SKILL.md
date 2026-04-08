---
name: eks-investigation
description: Investigation procedures for EKS cluster issues including cluster health, node failures, pod crashes, scheduling problems, networking errors, DNS resolution, and control plane connectivity. Use this skill when investigating EKS pod failures, node not-ready, service unreachability, OOMKilled containers, or Kubernetes API errors.
---

# EKS Cluster Investigation

Use this skill when operators report Kubernetes issues such as pod failures, node not-ready conditions, service connectivity problems, deployment rollout failures, or control plane errors.

## Step 1: Identify the affected cluster

Determine the EKS cluster name, region, account, and Kubernetes version. Query the cluster status and confirm whether it is ACTIVE, CREATING, UPDATING, or FAILED.

Retrieve cluster metadata:
- Kubernetes version, platform version
- VPC, subnets (control plane ENIs)
- Cluster endpoint (public/private access configuration)
- Logging configuration (api, audit, authenticator, controllerManager, scheduler)
- Add-ons and their versions (vpc-cni, kube-proxy, coredns, ebs-csi-driver)
- Node groups (managed, self-managed, Fargate profiles)

## Step 2: Check cluster-level CloudWatch metrics and logs

**Control plane metrics** (if control plane logging is enabled):
- Check CloudWatch Logs group `/aws/eks/<cluster-name>/cluster` for:
  - API server errors (5xx responses)
  - Authentication/authorization failures
  - Admission webhook rejections
  - etcd latency warnings

**Container Insights metrics** (if enabled):
- `cluster_failed_node_count` — nodes in NotReady state
- `cluster_node_count` — total vs expected node count
- `namespace_number_of_running_pods` — pod count by namespace
- `node_cpu_utilization` / `node_memory_utilization` — per-node resource usage
- `pod_cpu_utilization` / `pod_memory_utilization` — per-pod resource usage

See [eks-metrics-reference.md](references/eks-metrics-reference.md) for full metric details.

## Step 3: Investigate node issues

If nodes are in NotReady state or missing:

1. **Check node group status**:
   - Managed node group: check health status, scaling activity, update status
   - Auto Scaling group: check desired vs actual capacity, scaling events, instance health

2. **EC2 instance health**:
   - Check EC2 status checks for the node instances
   - Review instance system log for kubelet startup errors
   - Verify instance profile has required IAM permissions (AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly)

3. **Node capacity**:
   - Instance type determines max pods (ENI limit × IPs per ENI - 1)
   - Check if nodes are at pod capacity (`Allocatable` pods vs running pods)
   - Verify sufficient CPU and memory allocatable resources

4. **Node group scaling**:
   - Check Auto Scaling group events for launch failures
   - Verify launch template AMI is compatible with cluster Kubernetes version
   - Check for subnet IP address exhaustion
   - Review Cluster Autoscaler or Karpenter logs for scaling decisions

5. **Common NotReady causes**:
   - kubelet cannot reach API server (security group, endpoint access)
   - Container runtime (containerd) failure
   - Node disk pressure (ephemeral storage exhausted)
   - CNI plugin failure (vpc-cni pod not running)

## Step 4: Investigate pod failures

If pods are in CrashLoopBackOff, Error, Pending, or OOMKilled:

### CrashLoopBackOff
1. Check container exit code and logs from previous container instance
2. Common causes:
   - Application startup failure (missing config, bad environment variables)
   - Health check failure (liveness probe failing)
   - Dependency unavailable (database, external service)
   - Exit code 137 = OOMKilled, exit code 1 = application error

### Pending pods
1. Check events on the pod for scheduling failure reasons
2. Common causes:
   - Insufficient CPU/memory resources across nodes
   - Node selector or affinity rules cannot be satisfied
   - Taints on nodes with no matching tolerations
   - PersistentVolumeClaim not bound (EBS CSI driver issue, AZ mismatch)
   - Too many pods per node (ENI/IP limits reached)

### OOMKilled
1. Container exceeded its memory limit
2. Check actual memory usage vs configured limit
3. Look for memory leaks (steady increase over time)
4. Consider increasing memory limit or optimizing application memory usage
5. Check if JVM-based apps have `-Xmx` set appropriately relative to container limit

### ImagePullBackOff
1. Verify image exists in the registry (ECR, Docker Hub)
2. Check ECR permissions (node instance profile needs `ecr:GetDownloadUrlForLayer`)
3. Verify image pull secrets for private registries
4. Check for ECR VPC endpoint if cluster is in private subnets

## Step 5: Investigate networking issues

If services are unreachable or pods cannot communicate:

1. **Pod-to-pod connectivity**:
   - Check VPC CNI plugin (`aws-node` DaemonSet) status on all nodes
   - Verify WARM_ENI_TARGET / WARM_IP_TARGET / MINIMUM_IP_TARGET settings
   - Check subnet available IP addresses (CNI needs IPs for pods)
   - Verify security groups allow pod-to-pod traffic

2. **Service discovery (DNS)**:
   - Check CoreDNS pods are running and healthy
   - Verify CoreDNS ConfigMap for custom domain configuration
   - Test DNS resolution from within a pod (`nslookup <service>.<namespace>.svc.cluster.local`)
   - Check CoreDNS metrics for NXDOMAIN or SERVFAIL responses

3. **Ingress / LoadBalancer**:
   - Check AWS Load Balancer Controller pods are running
   - Verify target group health checks are passing
   - Check security group rules on the load balancer
   - Verify service annotations for NLB/ALB configuration
   - Check for subnet tag requirements (`kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`)

4. **Network policies**:
   - If Calico or other CNI network policy is in use, check for deny rules
   - Review NetworkPolicy objects in the affected namespace

5. **Cross-namespace / cross-cluster**:
   - Verify RBAC allows cross-namespace access
   - Check VPC peering or transit gateway routes for cross-cluster

## Step 6: Investigate control plane issues

If kubectl commands are failing or the API server is unresponsive:

1. **Endpoint access**:
   - Verify cluster endpoint access configuration (public, private, or both)
   - If private only, confirm VPC connectivity from the client
   - Check API server allowed CIDR blocks

2. **Authentication**:
   - Verify aws-auth ConfigMap is correct (maps IAM roles/users to Kubernetes groups)
   - Check if IAM authenticator is returning errors (CloudWatch Logs)
   - Verify caller's IAM permissions include `eks:DescribeCluster`

3. **API server throttling**:
   - Check for 429 (Too Many Requests) responses in audit logs
   - Identify clients making excessive API calls
   - Check for misbehaving controllers or operators

4. **Add-on health**:
   - CoreDNS: cluster DNS resolution
   - kube-proxy: service routing and iptables rules
   - VPC CNI: pod networking and IP allocation
   - EBS CSI driver: persistent volume provisioning

## Step 7: Summarize findings

Provide a summary with:
1. Cluster identification (name, version, region, account)
2. Current cluster, node, and workload health status
3. Root cause hypothesis with supporting metrics, events, and logs
4. Impact assessment (affected workloads, namespaces, duration)
5. Recommended remediation steps ranked by priority
6. Preventive measures (monitoring, resource limits, scaling policies)
