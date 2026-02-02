pipeline {
    agent any

    environment {
        MOBSF_API_KEY = credentials('mobsf-api-key')
        MOBSF_URL = "http://host.docker.internal:8000"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Code checked out from GitHub'
            }
        }

        stage('Docker Check') {
            steps {
                sh 'docker --version'
            }
        }

        stage('Upload APK to MobSF') {
            steps {
                sh '''
                echo "Uploading APK to MobSF..."

                RESPONSE=$(curl -s -X POST \
                  -H "Authorization:${MOBSF_API_KEY}" \
                  -F "file=@apk/InsecureBankv2.apk" \
                  ${MOBSF_URL}/api/v1/upload)

                echo "$RESPONSE"

                HASH=$(echo "$RESPONSE" | jq -r '.hash')

                echo "APK Hash: $HASH"
                echo "$HASH" > apk_hash.txt
                '''
            }
        }

        stage('Security Gate – MobSF') {
            steps {
                sh '''
                HASH=$(cat apk_hash.txt)

                echo "Fetching MobSF report..."

                REPORT=$(curl -s -X POST \
                  -H "Authorization:${MOBSF_API_KEY}" \
                  -d "hash=$HASH" \
                  ${MOBSF_URL}/api/v1/report_json)

                HIGH=$(echo "$REPORT" | jq '.high | length')
                CRITICAL=$(echo "$REPORT" | jq '.critical | length')

                echo "High vulnerabilities: $HIGH"
                echo "Critical vulnerabilities: $CRITICAL"

                if [ "$HIGH" -gt 0 ] || [ "$CRITICAL" -gt 0 ]; then
                    echo "❌ SECURITY GATE FAILED – Vulnerabilities found"
                    exit 1
                else
                    echo "✅ SECURITY GATE PASSED – App is safe"
                fi
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline PASSED – Application is secure'
        }
        failure {
            echo 'Pipeline FAILED – Security issues detected'
        }
    }
}
