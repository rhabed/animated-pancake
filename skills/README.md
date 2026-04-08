# AWS DevOps Agent Skills

Skills extend the AWS DevOps Agent with domain-specific investigation procedures. Each skill is a structured prompt that guides the agent through a step-by-step diagnostic workflow for a particular AWS service or problem domain.

## Available Skills

| Skill | Folder | Use When |
|-------|--------|----------|
| EC2 Investigation | `ec2-investigation/` | EC2 instance unreachable, status check failures, CPU/memory/disk pressure, launch failures |
| EKS Investigation | `eks-investigation/` | Pod crashes, node not-ready, service unreachability, DNS failures, control plane errors |
| Lambda Investigation | `lambda-investigation/` | Invocation errors, timeouts, throttling, cold starts, event source integration issues |
| RDS Investigation | `rds-investigation/` | Connection exhaustion, slow queries, replication lag, storage alerts, failover events |

Each skill folder contains:
- `SKILL.md` — the skill definition loaded by the agent
- `references/` — metric thresholds and reference tables used in the investigation steps

---

## Adding a Skill via the AWS DevOps Agent UI

Skills are added to an Agent Space through the **Operator App** — the web interface deployed alongside the Agent Space when `enable_operator_app = true`. Each skill corresponds to a `SKILL.md` file in this repository.

### Prerequisites

- An active Agent Space with the Operator App enabled (`enable_operator_app = true`)
- The Operator App URL (retrieve from Terraform output: `terraform output operator_app_url`)
- The contents of the `SKILL.md` file you want to add

### Steps

1. **Open the Operator App**

   Navigate to the Operator App URL and sign in.

2. **Go to Skills**

   In the Operator App, open the **Settings** menu and select **Skills**, then click **Add skill**.

3. **Set the skill name**

   Enter the skill name exactly as it appears in the `name` field at the top of the `SKILL.md` file.

   Example — for `ec2-investigation/SKILL.md`:
   ```
   name: ec2-investigation
   ```

4. **Set the skill description**

   Copy the `description` field from the frontmatter of the `SKILL.md` file into the **Description** field. This is what the agent uses to decide when to invoke the skill.

   Example:
   ```
   Investigation procedures for EC2 instance issues including instance health checks,
   status check failures, connectivity problems, CPU and memory pressure, EBS volume
   performance, and capacity errors. Use this skill when investigating EC2 instance
   unreachability, degraded performance, launch failures, or status check alarms.
   ```

5. **Set the skill content**

   Copy the full body of the `SKILL.md` file (everything below the `---` frontmatter block) into the **Content** field.

6. **Save the skill**

   Click **Save**. The skill is now available to the agent and will be invoked automatically when the agent determines it matches the issue being investigated.

### Repeat for Each Skill

Repeat steps 2–6 for each skill you want to add:

| Skill name | File |
|------------|------|
| `ec2-investigation` | `skills/ec2-investigation/SKILL.md` |
| `eks-investigation` | `skills/eks-investigation/SKILL.md` |
| `lambda-investigation` | `skills/lambda-investigation/SKILL.md` |
| `rds-investigation` | `skills/rds-investigation/SKILL.md` |

---

## Adding a New Skill

To contribute a new skill to this repository:

1. Create a new folder under `skills/` named after the skill (e.g. `skills/s3-investigation/`)
2. Add a `SKILL.md` file with the following frontmatter:
   ```markdown
   ---
   name: <skill-name>
   description: <one or two sentences describing when the agent should use this skill>
   ---

   # <Skill Title>

   ...investigation steps...
   ```
3. Optionally add a `references/` subfolder with metric reference tables or supporting documentation
4. Register the skill in the Agent Space UI following the steps above
