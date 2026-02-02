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

        stage('Security Gate – MobSF (Polling)') {
            steps {
                sh '''
                HASH=$(cat apk_hash.txt)
                MAX_TRIES=10
                COUNT=0

                echo "Waiting for MobSF scan to complete..."

                while true; do
                    REPORT=$(curl -s -X POST \
                      -H "Authorization:${MOBSF_API_KEY}" \
                      -d "hash=$HASH" \
                      ${MOBSF_URL}/api/v1/report_json)

                    READY=$(echo "$REPORT" | jq -r '.report')

                    if [ "$READY" != "Report not Found" ]; then
                        echo "Report ready!"
                        break
                    fi

                    COUNT=$((COUNT+1))
                    if [ "$COUNT" -ge "$MAX_TRIES" ]; then
                        echo "❌ MobSF scan timeout"
                        exit 1
                    fi

                    echo "Scan not ready yet… retrying"
                    sleep 5
                done

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
            echo 'Pipeline FAILED – Security vulnerabilities detected'
        }
    }
}
