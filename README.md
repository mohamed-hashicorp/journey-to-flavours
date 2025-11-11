# Terraform: Automated EC2 Deployment (Work in Progress - Towards Flavours)

This repository contains **Terraform automation** for deploying EC2 instances on AWS with different base operating systems and container runtimes.  

The goal is to standardize and automate the creation of servers that include:

- A public IP address
- A friendly Fully Qualified Domain Name (FQDN)
- Docker or Podman pre-installed (depending on the flavor)

This work complements existing manual documentation stored in Confluence.

---

## Repository Structure

Each directory in this repository represents one deployment “flavor”.  
The Terraform code inside each directory provisions the EC2 instance and configures the required runtime.

```
├── README.md ← You are here
├── amazon-linux-docker ← Amazon Linux + Docker + Public IP + FQDN
├── amazon-linux-podman ← Amazon Linux + Podman + Public IP + FQDN
└── ubuntu-podman ← Ubuntu LTS + Podman + Public IP + FQDN
```

---

## What Each Automated Deployment Does

| Deployment Type | OS | Container Runtime | Result |
|-----------------|----|------------------|--------|
| `amazon-linux-docker` | Amazon Linux | Docker | EC2 with Docker installed + reachable via FQDN |
| `amazon-linux-podman` | Amazon Linux | Podman | EC2 with Podman installed + reachable via FQDN |
| `ubuntu-podman` | Latest Ubuntu LTS | Podman | EC2 with Podman installed + reachable via FQDN |

Each deployment:
1. Creates an EC2 instance.
2. Allocates or uses an Elastic IP.
3. Configures DNS in Route 53 to map the hostname → external IP.
4. Installs and enables Docker/Podman automatically via user data or provisioners.



## Requirements

Before using the repository, ensure you have:

- An **AWS account** with access to deploy EC2 & Route 53 resources
- A **domain name** managed in **Route 53** (or ability to update nameservers)
- Terraform v1.5+ installed locally

