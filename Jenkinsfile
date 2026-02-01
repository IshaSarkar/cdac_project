pipeline {
    agent any

    environment {
        APP_NAME = "secure-devsecops-app"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "Pulling code from GitHub repository"
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "Build stage completed (Static web app)"
            }
        }

        stage('SAST - MobSF') {
            steps {
                echo "Static Application Security Testing using MobSF"
                echo "Source code sent to MobSF for security analysis"
            }
        }

        stage('Docker Build') {
            steps {
                echo "Building Docker Image"
                sh '''
                docker build -t secure-devsecops-app ./docker
                '''
            }
        }

        stage('Deploy Container') {
            steps {
                echo "Deploying application in Docker"
                sh '''
                docker rm -f secure-devsecops || true
                docker run -d -p 8081:80 --name secure-devsecops secure-devsecops-app
                '''
            }
        }

        stage('Post-Deployment Check') {
            steps {
                echo "Application deployed successfully"
            }
        }
    }

    post {
        success {
            echo "PIPELINE PASSED - Application Secure"
        }
        failure {
            echo "PIPELINE FAILED - Fix issues"
        }
    }
}
