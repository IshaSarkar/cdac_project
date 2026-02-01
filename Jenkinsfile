pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/IshaSarkar/secure-devsecops-project.git'
            }
        }

        stage('Build') {
            steps {
                echo "Build stage running"
            }
        }

        stage('SAST - MobSF') {
            steps {
                echo "Static Security Analysis using MobSF"
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying application using Docker"
            }
        }
    }
}
