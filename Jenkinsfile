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
        
        stage('Security Gate') {
    environment {
        MOBSF_API_KEY = credentials('mobsf-api-key')
    }
    steps {
        sh '''
        echo "Fetching MobSF scan hash..."

        HASH=$(curl -s -H "Authorization:${MOBSF_API_KEY}" \
        http://host.docker.internal:8000/api/v1/scans | jq -r '.[0].hash')

        echo "Scan hash is: $HASH"

        REPORT=$(curl -s -H "Authorization:${MOBSF_API_KEY}" \
        -X POST \
        -d "hash=$HASH" \
        http://host.docker.internal:8000/api/v1/report_json)

        HIGH=$(echo "$REPORT" | jq '.high | length')
        CRITICAL=$(echo "$REPORT" | jq '.critical | length')

        echo "High vulnerabilities: $HIGH"
        echo "Critical vulnerabilities: $CRITICAL"

        if [ "$HIGH" -gt 0 ] || [ "$CRITICAL" -gt 0 ]; then
            echo "❌ Security Gate FAILED – Vulnerabilities found"
            exit 1
        else
            echo "✅ Security Gate PASSED – App is safe"
        fi
        '''
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
