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

                echo "$RESPONSE"

                HASH=$(echo "$RESPONSE" | jq -r '.hash')

                if [ "$HASH" = "null" ] || [ -z "$HASH" ]; then
                    echo "❌ Failed to get APK hash from MobSF"
                    exit 1
                fi

                echo "$HASH" > apk_hash.txt
                echo "APK Hash: $HASH"
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

                echo "Fetching MobSF report..."

                REPORT=$(curl -s -X POST \
                  -H "Authorization:${MOBSF_API_KEY}" \
                  -d "hash=$HASH" \
                  ${MOBSF_URL}/api/v1/report_json)

                HIGH=$(echo "$REPORT" | jq '.appsec.high | length')
                WARNING=$(echo "$REPORT" | jq '.appsec.warning | length')

                echo "High vulnerabilities: $HIGH"
                echo "Warnings: $WARNING"

                if [ "$HIGH" -gt 0 ]; then
                    echo "❌ SECURITY GATE FAILED – High vulnerabilities found"
                    exit 1
                else
                    echo "✅ SECURITY GATE PASSED – No high vulnerabilities"
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
