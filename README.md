# Node.js Project Deployment on AWS EKS with CI/CD and CloudWatch Monitoring

## **Project Overview**

This is a **Node.js project** deployed on **Kubernetes (EKS)** with full CI/CD automation and monitoring setup. The project leverages multiple DevOps tools for **infrastructure provisioning, deployment, and monitoring**.

---

## **Tools & Technologies Used**

| Tool/Technology | Purpose |
|-----------------|---------|
| **Terraform** | Infrastructure as Code (IaC) |
| **AWS** | Cloud Platform |
| **Git & GitHub** | Version Control & Source Code Management |
| **Jenkins** | Continuous Integration / Continuous Deployment |
| **Node.js & npm** | Backend runtime & package management |
| **Docker** | Containerization & Image Build |
| **Docker Hub** | Docker image repository |
| **EKS (Elastic Kubernetes Service)** | Kubernetes Cluster for Deployment |
| **CloudWatch** | Monitoring and Container Insights |

<img width="2048" height="2048" alt="image" src="https://github.com/user-attachments/assets/ec7557af-8282-4b67-aaa1-db5083ed2d87" />

---

## **Deployment Environments**

The project is deployed across **two environments**:

1. **Development Environment**
2. **Main Deployment Environment**

---

## **Step 1: Infrastructure Provisioning with Terraform**

1. Clone the repository on your local machine or server:
   ```bash
   git clone https://github.com/pj013525/internship-devops-task.git
   cd internship-devops-task
Initialize and apply Terraform configurations:

bash
Copy code
terraform init
terraform apply --auto-approve
Get the public IP of the created server(s) from the AWS console.

Step 2: Development Environment Setup
Login to server-1 using MobaXterm.

Clone the project repo (if not already):

bash
Copy code
git clone https://github.com/pj013525/internship-devops-task.git
cd internship-devops-task
Install Node.js & npm:

bash
Copy code
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22
node -v    # Verify Node.js
npm -v     # Verify npm
Install dependencies and run the application:

bash
Copy code
npm install
npm start
Open browser at:

Copy code
http://<server-public-ip>:3000

<img width="1185" height="676" alt="chrome_NVpZ7l9sok" src="https://github.com/user-attachments/assets/75a632ce-4283-48c9-85b5-eab74c7f00a8" />

Step 3: Main Deployment Environment Setup
Create IAM Role with following policies:

AmazonEC2FullAccess

AmazonEKS_CNI_Policy

AmazonEKSClusterPolicy

AmazonEKSWorkerNodePolicy

AWSCloudFormationFullAccess

IAMFullAccess

CloudWatchAgentServerPolicy

Custom Policy (EKS Full Access):

json
Copy code
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "eks:*",
      "Resource": "*"
    }
  ]
}
Create IAM user and save credentials.

Step 4: Install Required Tools on Server-1
bash
Copy code
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
aws configure

# kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.30.14/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
Step 5: Create EKS Cluster
bash
Copy code
eksctl create cluster --name=devops-cluster \
  --region=ap-south-2 \
  --zones=ap-south-2a,ap-south-2b \
  --version=1.30 \
  --without-nodegroup \
  --with-oidc

eksctl utils update-cluster-logging \
  --region=ap-south-2 \
  --cluster=devops-cluster \
  --enable-types all \
  --approve

eksctl create nodegroup --cluster=devops-cluster \
  --region=ap-south-2 \
  --name=node2 \
  --node-type=t3.medium \
  --nodes=3 \
  --nodes-min=2 \
  --nodes-max=4 \
  --node-volume-size=20 \
  --ssh-access \
  --ssh-public-key=devops-test \
  --managed \
  --asg-access \
  --external-dns-access \
  --full-ecr-access \
  --appmesh-access \
  --alb-ingress-access

kubectl get nodes
Step 6: RBAC & Deployment
Create namespace for project:

bash
Copy code
kubectl create namespace pj-namespace
Apply RBAC manifests (service.yaml, role.yaml, bind.yaml, secret.yaml) from repo.

Deploy the application to EKS:

bash
Copy code
kubectl apply -f deployment.yaml -n pj-namespace
kubectl apply -f service.yaml -n pj-namespace

Step 7: Jenkins CI/CD Setup (Server-2)
Install:

Java 17, Jenkins, Docker, kubectl

Access Jenkins:

pgsql
Copy code
http://<server-2-public-ip>:8080
Install required Jenkins plugins:

arduino
Copy code
NodeJS, Pipeline StageView, Pipeline NPM Integration,
Docker, Docker Pipeline, Docker Commons, Docker API,
Kubernetes, Kubernetes Client API, Kubernetes Pipeline
Configure pipeline stages:

Clone code from GitHub

Install dependencies

Run tests (npm test/start)

Build & tag Docker image

Push image to Docker Hub

Deploy to EKS

<img width="1366" height="616" alt="chrome_5EQEB8PXyg" src="https://github.com/user-attachments/assets/42d8c8bb-08ca-4452-ad7b-c06172b71062" />

Step 8: GitHub Webhook Setup
Go to GitHub Repo → Settings → Webhooks → Add webhook

bash
Copy code
Payload URL: http://<jenkins-server-ip>:8080/github-webhook/
Content type: application/json
In Jenkins → Pipeline Triggers → Enable GitHub hook trigger for GIT SCM polling.

Any push to GitHub triggers automated build and deployment.

Step 9: CloudWatch Monitoring (Container Insights)
Create namespace for CloudWatch:

bash
Copy code
kubectl create namespace amazon-cloudwatch
Create IAM role with CloudWatchAgentServerPolicy and EKS full access.

Install CloudWatch observability add-on:

bash
Copy code
aws eks create-addon \
  --cluster-name devops-cluster \
  --addon-name amazon-cloudwatch-observability \
  --service-account-role-arn <CloudWatchAgentRoleARN> \
  --region ap-south-2
Verify status:

bash
Copy code
aws eks describe-addon \
  --cluster-name devops-cluster \
  --addon-name amazon-cloudwatch-observability \
  --region ap-south-2
Configure CloudWatch agent to monitor pj-namespace:

bash
Copy code
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cwagentconfig
  namespace: amazon-cloudwatch
  labels:
    app: cloudwatch-agent
data:
  cwagentconfig.json: |
    {
      "logs": {
        "logs_collected": {
          "kubernetes": {
            "cluster_name": "devops-cluster",
            "metrics_collection_interval": 60,
            "namespace": ["pj-namespace"]
          }
        }
      }
    }
EOF
Restart CloudWatch agent:

bash
Copy code
kubectl rollout restart daemonset cloudwatch-agent -n amazon-cloudwatch
Verify DaemonSets and logs:

bash
Copy code
kubectl get daemonset -n amazon-cloudwatch
kubectl logs -n amazon-cloudwatch -l app=cloudwatch-agent
kubectl logs -n amazon-cloudwatch -l app=fluent-bit
View metrics in AWS Console → CloudWatch → Container Insights → devops-cluster.

Step 10: Access Application
After deployment, get LoadBalancer URL from kubectl get svc -n pj-namespace

Open in browser to verify.
<img width="952" height="679" alt="chrome_AIb6RqJhGV" src="https://github.com/user-attachments/assets/7612062a-2426-47d4-9774-02e43e4137ed" />

Notes
Metrics and logs in CloudWatch may take 2–5 minutes to appear.

Make sure IAM roles and service account permissions are correct.

This setup supports Dev + Main environments with CI/CD automation.

