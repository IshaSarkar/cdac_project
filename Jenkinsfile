pipeline {
    agent any

    environment {
        MOBSF_URL = "http://mobsf:8000"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Code checked out from GitHub'
            }
        }

        stage('Build') {
            steps {
                echo 'Build stage running'
            }
        }

        stage('Docker Check') {
            steps {
                sh 'docker --version'
            }
        }

        stage('MobSF SAST Scan') {
            environment {
                MOBSF_API_KEY = credentials('mobsf-api-key')
            }
            steps {
                sh '''
                echo "Uploading APK to MobSF for security scanning..."
		curl -X POST \
		  -H "Authorization:${MOBSF_API_KEY}" \
		  -F "file=@apk/InsecureBankv2.apk" \
 		 http://host.docker.internal:8000/api/v1/upload


		 '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
