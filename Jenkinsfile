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

        stage('Docker Check') {
            steps {
                sh 'docker --version'
            }
        }

        stage('Upload APK to MobSF') {
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

                echo "MobSF Upload Response:"
                echo "$RESPONSE"

                HASH=$(echo "$RESPONSE" | jq -r '.hash')

                if [ "$HASH" = "null" ] || [ -z "$HASH" ]; then
                    echo "❌ Failed to get APK hash"
                    exit 1
                fi

                echo "$HASH" > apk_hash.txt
                echo "APK Hash saved: $HASH"
                '''
            }
        }

        stage('Wait for MobSF Scan') {
            steps {
                sh '''
                echo "Waiting for MobSF to complete analysis..."
                sleep 30
                '''
            }
        }

        stage('Security Gate – MobSF') {
            environment {
                MOBSF_API_KEY = credentials('mobsf-api-key')
            }
            steps {
                sh '''
                HASH=$(cat apk_hash.txt)

                REPORT=$(curl -s -X POST \
                  -H "Authorization:${MOBSF_API_KEY}" \
                  -d "hash=$HASH" \
                  ${MOBSF_URL}/api/v1/report_json)

                echo "MobSF Security Report:"
                echo "$REPORT"

                HIGH=$(echo "$REPORT" | jq '.appsec.high | length')
                WARNING=$(echo "$REPORT" | jq '.appsec.warning | length')

                echo "High Vulnerabilities: $HIGH"
                echo "Warnings: $WARNING"

                if [ "$HIGH" -gt 0 ]; then
                    echo "❌ SECURITY GATE FAILED – Vulnerable APK detected"
                    exit 1
                else
                    echo "✅ SECURITY GATE PASSED – APK is secure"
                fi
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline PASSED – Application is secure'
        }
        failure {
            echo '❌ Pipeline FAILED – Security vulnerabilities detected'
        }
    }
}
