# DevOps Bootcamp Final Project — Documentation

## Final URLs (Mandatory)
- **Web Application:** http://web.ahmaddm.com  
- **Monitoring (Grafana):** https://monitoring.ahmaddm.com  
- **GitHub Repository:** https://github.com/AHMAD-DM-17/devops-bootcamp-project  

## Overview
Design, provision, configure, deploy, monitor, and document a complete DevOps-based system using industry-standard tools and practices.

## Step-by-step Setup Guide (Recommended)

### A. Prerequisites
1. Create GitHub repository: **devops-bootcamp-project**
2. Create folders: **terraform/**, **ansible/** and update **README.md**
3. Create folder **assets/** and upload the project PDF + architecture diagram

### B. IAM + AWS CLI Setup → S3 Terraform State Bucket (Hardened)

**IAM User / Profile:** AhmadAfif  
**AWS Region:** ap-southeast-1  
**Terraform State Bucket:** devops-bootcamp-terraform-ahmadafif  

#### 1) Create IAM user
Created IAM user: **AhmadAfif**  
Purpose: allow AWS CLI + Terraform to provision AWS infrastructure for the bootcamp project.

#### 2) Attach IAM permissions
Attached AWS managed policies:
- AdministratorAccess
- IAMUserChangePassword

#### 3) Configure AWS CLI profiles on laptop
```bash
aws sts get-caller-identity
aws sts get-caller-identity --profile AhmadAfif

aws iam list-attached-user-policies \
  --user-name AhmadAfif \
  --profile AhmadAfif \
  --output table
```

#### 4) Confirm key pair situation (EC2 access)
Checked key pairs in the target region:
```bash
    aws ec2 describe-key-pairs \
      --region ap-southeast-1 \
      --query "KeyPairs[].KeyName" \
      --output table
```
Verify key file exists:   
```bash
    ls -la *.pem
```

#### 5) Set environment for this project session
Exported AWS profile and region for the terminal session:
```bash
    export AWS_PROFILE=AhmadAfif
    export AWS_REGION=ap-southeast-1
```

#### 6) Create S3 bucket for Terraform state (bootstrap)
Defined a globally-unique bucket name:
```bash
    BUCKET="devops-bootcamp-terraform-ahmadafif"
```
Created the bucket in ap-southeast-1:
```bash
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region ap-southeast-1 \
      --create-bucket-configuration LocationConstraint=ap-southeast-1
```
Verify bucket region:
```bash
    aws s3api get-bucket-location --bucket "$BUCKET"
```

Enforce HTTPS-only access (deny insecure transport):
This policy blocks any S3 request made over plain HTTP by denying requests where `aws:SecureTransport` is `false`. It helps protect Terraform state traffic in transit and ensures the bucket is accessed only via TLS.

```bash
BUCKET="devops-bootcamp-terraform-ahmadafif"

cat > bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$BUCKET",
        "arn:aws:s3:::$BUCKET/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket "$BUCKET" --policy file://bucket-policy.json
```

### C. Terraform Infrastructure Provisioning → VPC + EC2 + SSM + ECR
This section provisions the required AWS infrastructure using Terraform under terraform/infra/, using the existing S3 state bucket as backend.
  Key design goals
      Repeatable: re-running Terraform produces the same infra (idempotent)
      Safe: remote state + no sensitive config committed
      Matches required architecture: VPC, subnets, NAT/IGW routing, 3 EC2 servers, SSM enabled, ECR repo

#### 1) Create working folder structure
This keeps code organized and matches the bootcamp expectation that Terraform lives under /terraform.
```bash
cd ~/devops-bootcamp-project
mkdir -p terraform/infra
```
#### 2) Create backend configuration file
This tells Terraform where the remote state lives.
File: terraform/infra/backend.hcl
    Backend is initialized once with terraform init -backend-config=backend.hcl
    backend.hcl should not be committed because it’s environment-specific.

#### 3) Add .gitignore rules for Terraform state & backend files
Purpose for not commit .tfstate or local .terraform/ folders.

#### 4) Create the Terraform backend + provider scaffolding
Terraform needs an AWS provider and an S3 backend definition.
  Files:
    terraform/infra/backend.tf
    terraform/infra/providers.tf
    
#### 5) Define variables + local constants (project defaults)
Keeps the config readable and reduces duplication.
  Files:
      variables.tf (inputs)
      locals.tf (CIDRs/IPs/tags)

This project uses:
      yourname = ahmadafif
      key_name = AhmadAfifKey
      region ap-southeast-1

#### 6) Provision networking (VPC, subnets, IGW, NAT GW, routes)
This creates the network foundation:
  Public subnet for web server (with EIP)
  Private subnet for ansible + monitoring
  NAT allows private instances to reach internet (updates, packages) without public IP

Resources included:
  VPC 10.0.0.0/24
  Public subnet 10.0.0.0/25
  Private subnet 10.0.0.128/25
  IGW for public subnet
  NAT GW for private subnet outbound access
  Route tables for public/private

File: terraform/infra/vpc.tf

#### 7) Configure security groups (least privilege)
Controls what can talk to what.
  Public SG (web):
      Allow HTTP 80 from anywhere
      Allow Node exporter 9100 only from monitoring server private IP (10.0.0.136/32)
      Allow SSH 22 from inside VPC only (10.0.0.0/24)
  
  Private SG (ansible + monitoring): Allow SSH 22 from inside VPC only
  File: terraform/infra/security_groups.tf

#### 8) Enable SSM (Systems Manager) on all servers
Required for secure management, especially for private instances with no public IP.
Terraform does this by attaching an IAM role with: AmazonSSMManagedInstanceCore
File: terraform/infra/iam_ssm.tf

#### 9) Provision EC2 instances (3 servers) + Elastic IP for web
Creates the required compute layer with fixed private IPs so:
    Security rules are predictable
    Ansible inventory is stable
    Monitoring scrape targets are consistent

Instances:
Web server (public subnet): private IP 10.0.0.5, Elastic IP associated
Ansible controller (private subnet): private IP 10.0.0.135, no public IP
Monitoring server (private subnet): private IP 10.0.0.136, no public IP
Additionally, user_data installs & starts SSM agent so the instances appear in AWS Systems Manager.

File:terraform/infra/ec2.tf

#### 10) Create ECR repository + outputs, then run Terraform
ECR repo is needed to store container images for deployment
outputs provide the values needed for Cloudflare DNS + Ansible inventory

ECR: devops-bootcamp/final-project-ahmadafif
Files: terraform/infra/ecr.tf
terraform/infra/outputs.tf

Run commands:
```bash
cd ~/devops-bootcamp-project/terraform/infra

terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Verify Output : 
```bash
terraform output
```

Verify SSM Online :
```bash
aws ssm describe-instance-information \
  --query "InstanceInformationList[].{InstanceId:InstanceId,PingStatus:PingStatus}" \
  --output table
```

currently on ansible. ))


















