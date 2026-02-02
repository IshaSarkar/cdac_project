pipeline {
    agent any

    environment {
        MOBSF_URL = "http://host.docker.internal:8000"
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
                echo "Uploading APK to MobSF..."

                RESPONSE=$(curl -s -X POST \
                  -H "Authorization:${MOBSF_API_KEY}" \
                  -F "file=@apk/InsecureBankv2.apk" \
                  ${MOBSF_URL}/api/v1/upload)

                echo "Upload Response:"
                echo "$RESPONSE"

                HASH=$(echo "$RESPONSE" | jq -r '.hash')

                if [ "$HASH" = "null" ] || [ -z "$HASH" ]; then
                    echo "❌ APK upload failed"
                    exit 1
                fi

                echo "APK Hash: $HASH"

                echo "Fetching MobSF report..."

                REPORT=$(curl -s -X POST \
                  -H "Authorization:${MOBSF_API_KEY}" \
                  -d "hash=$HASH" \
                  ${MOBSF_URL}/api/v1/report_json)

                echo "Parsing vulnerabilities..."

                HIGH=$(echo "$REPORT" | jq '.high | length')
                CRITICAL=$(echo "$REPORT" | jq '.critical | length')

                echo "High vulnerabilities: $HIGH"
                echo "Critical vulnerabilities: $CRITICAL"

                if [ "$HIGH" -gt 0 ] || [ "$CRITICAL" -gt 0 ]; then
                    echo "❌ SECURITY GATE FAILED – Vulnerabilities found"
                    exit 1
                else
                    echo "✅ SECURITY GATE PASSED – No critical issues"
                fi
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
