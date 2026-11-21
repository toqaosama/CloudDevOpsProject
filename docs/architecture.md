# Architecture

## 1. Application

```mermaid
flowchart LR
    U[Browser] -->|HTTP| ING[Ingress nginx<br/>ivolve.local]
    U -->|HTTP| LB[Service frontend-lb<br/>LoadBalancer]
    ING --> FE[frontend<br/>Node.js :3000<br/>Deployment x2]
    LB --> FE
    FE -->|/api/auth/*| AUTH[auth-service<br/>Flask :5000<br/>Deployment x2]
    FE -->|/api/roadmap| RM[roadmap-service<br/>Spring Boot :8080<br/>Deployment x2]
    AUTH -->|mysql-0.mysql-headless:3306| DB[(MySQL 8.4<br/>StatefulSet)]
    DB --- PV[(PVC 5Gi<br/>StorageClass ivolve-mysql-sc)]
    CM[ConfigMap ivolve-config] -.-> FE & AUTH
    SEC[Secret ivolve-secret] -.-> FE & AUTH & DB
```

| Component | Kind | Port | Config |
|---|---|---|---|
| frontend | Deployment (2) + ClusterIP + Ingress + LoadBalancer | 3000 | AUTH_SERVICE_URL, ROADMAP_SERVICE_URL (ConfigMap), SESSION_SECRET (Secret) |
| auth-service | Deployment (2) + ClusterIP | 5000 | DB_HOST/PORT/NAME (ConfigMap), DB_USER/PASSWORD (Secret) |
| roadmap-service | Deployment (2) + ClusterIP | 8080 | – |
| mysql | StatefulSet (1) + headless service | 3306 | MYSQL_ROOT_PASSWORD, MYSQL_USER, MYSQL_PASSWORD (Secret), MYSQL_DATABASE (ConfigMap) |

Probes: readiness on HTTP endpoints (`/health`, `/api/roadmap`, `/`), liveness on TCP / `mysqladmin ping`,
startupProbe for MySQL so the first initialization is never interrupted.

## 2. CI/CD (GitOps)

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant J as Jenkins (agent "slave")
    participant R as Registry (ECR / minikube)
    participant A as Argo CD
    participant K as Kubernetes
    Dev->>GH: git push (code)
    J->>GH: checkout + load shared library (vars/)
    J->>J: Build Image (docker build)
    J->>J: Scan Image (trivy HIGH,CRITICAL)
    J->>R: Push Image (tag = build number)
    J->>J: Delete Image Locally
    J->>J: Update Manifests (newTag in kustomize overlay)
    J->>GH: Push Manifests (commit "[skip ci]")
    A->>GH: poll repo (auto-sync)
    A->>K: apply k8s/overlays/<env> (prune, self-heal)
```

## 3. AWS infrastructure (Terraform)

```mermaid
flowchart TB
    subgraph VPC[VPC 10.0.0.0/16 - us-east-1]
      subgraph AZ1[AZ a]
        PUB1[public 10.0.1.0/24<br/>NAT GW + Jenkins EC2]
        PRI1[private 10.0.11.0/24<br/>EKS node group 1]
      end
      subgraph AZ2[AZ b]
        PUB2[public 10.0.2.0/24]
        PRI2[private 10.0.12.0/24<br/>EKS node group 2]
      end
      IGW[Internet Gateway] --- PUB1 & PUB2
      PRI1 & PRI2 -->|0.0.0.0/0| NAT[NAT Gateway]
    end
    EKS[EKS control plane] --- PRI1 & PRI2
    ECR[(ECR: frontend, auth-service, roadmap-service)]
    S3[(S3 remote state<br/>native locking)]
```

| Module | Resources |
|---|---|
| `network` | VPC, 2 public + 2 private subnets (2 AZs), IGW, NAT GW + EIP, route tables, public/private NACLs, EKS subnet tags |
| `server` | Jenkins EC2 (Ubuntu 24.04, gp3 encrypted, IMDSv2), security group (22/8080 from admin CIDR), IAM role + instance profile (ECR push, EKS describe), tag `role=jenkins` for Ansible |
| `eks` | cluster role, EKS cluster in the private subnets, node role, **one node group per private subnet** (2 nodes in 2 AZs), EBS CSI addon, access entry for the Jenkins role |
| `ecr` | one repository per microservice, scan on push, lifecycle policy (keep 10) |
| backend | S3 bucket from `terraform/bootstrap` (versioning, encryption, public access block), `use_lockfile = true` |

## 4. Environments (Kustomize)

| Overlay | Images | StorageClass | Used by |
|---|---|---|---|
| `k8s/overlays/local` | `localhost:5000/<service>` (minikube registry addon) | `k8s.io/minikube-hostpath` | `argocd/application.yaml` |
| `k8s/overlays/eks` | `<account>.dkr.ecr.us-east-1.amazonaws.com/clouddevops/<service>` | `ebs.csi.aws.com` gp3 | `argocd/application-eks.yaml` |
