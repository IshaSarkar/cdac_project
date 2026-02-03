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

                echo "Upload response:"
                echo "$RESPONSE"

                HASH=$(echo "$RESPONSE" | grep -o '"hash"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

                if [ -z "$HASH" ]; then
                    echo "❌ Failed to extract APK hash"
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
                echo "Waiting for MobSF analysis to complete..."
                sleep 30
                '''
            }
        }

        stage('Security Gate – MobSF') {
            environment {
                MOBSF_API_KEY = credentials('mobsf-api-key')
		MOBSF_URL     = 'http://192.168.80.112:8000'
            }
            steps {
                sh '''
                HASH=$(cat apk_hash.txt)

                echo "Fetching MobSF security report..."

                REPORT=$(curl -s -X POST \
                  -H "Authorization:${MOBSF_API_KEY}" \
                  -d "hash=$HASH" \
                  ${MOBSF_URL}/api/v1/report_json)

                VULN_COUNT=$(echo "$REPORT" | grep -o '"title"' | wc -l)

                echo "Total vulnerability findings: $VULN_COUNT"

                if [ "$VULN_COUNT" -gt 0 ]; then
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
            echo '✅ PIPELINE PASSED – Application is secure'
        }
        failure {
            echo '❌ PIPELINE FAILED – Security vulnerabilities detected'
        }
    }
}
