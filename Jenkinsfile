pipeline {
    agent any
    tools {
        jdk 'jdk-17'
        nodejs 'node-24'
    }
    environment {
        K8S_SERVER_URL = "https://FF8AC49860B492AF4D366142903F87D9.yl4.ap-south-2.eks.amazonaws.com"
        IMAGE_VERSION = "${BUILD_NUMBER}"
    }
    stages {
        stage('Clean the workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout the code') {
            steps {
                git branch: 'main', url: 'https://github.com/pj013525/internship-devops-task.git'
            }
        }
        stage('Install Dependency') {
            steps {
                sh 'npm install'
            }
        }
        stage('Run Unit Tests') {
            steps {
                sh '''
                if npm run | grep -q "test"; then
                    npm test
                else
                    echo "No test script found, skipping tests..."
                fi
                '''
            }
        }
        stage('Build and tag the Image') {
            steps {
                script {
                   withDockerRegistry(credentialsId: 'dockerhub-creds', toolName: 'docker') {
                      sh "docker build -t pj013525/pj-image:${IMAGE_VERSION} ."
                      sh "docker tag pj013525/pj-image:${IMAGE_VERSION} pj013525/pj-image:latest"
                   }
                }
            }
        }
        stage('Push the Docker Image') {
            steps {
                script {
                   withDockerRegistry(credentialsId: 'dockerhub-creds', toolName: 'docker') {
                      sh "docker push pj013525/pj-image:${IMAGE_VERSION}"
                      sh "docker push pj013525/pj-image:latest"
                      sh "docker image prune -f"
                   }
                }
            }
        }
        stage('Deploy in the K8S') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'pj', contextName: '', credentialsId: 'K8S-creds', namespace: 'pj-namespace', restrictKubeConfigAccess: false, serverUrl: "${K8S_SERVER_URL}") {
                    sh "cat deployment.yaml | envsubst | kubectl apply -n pj-namespace -f -"
                    sh "kubectl apply -f service.yaml -n pj-namespace"
                }
            }
        }
        stage('Verify the Deployment') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'pj', contextName: '', credentialsId: 'K8S-creds', namespace: 'pj-namespace', restrictKubeConfigAccess: false, serverUrl: "${K8S_SERVER_URL}") {
                    sleep 30
                    sh "kubectl get pods -n pj-namespace"
                    sh "kubectl get svc -n pj-namespace"
                }
            }
        }
    }
}

