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

