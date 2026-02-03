pipeline {
    agent any

    environment {
        MOBSF_URL = "http://192.168.80.112:8000"
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
                  -H "X-Mobsf-Api-Key: ${MOBSF_API_KEY}" \
                  -F "file=@apk/InsecureBankv2.apk" \
                  ${MOBSF_URL}/api/v1/upload)

                HASH=$(echo "$RESPONSE" | grep -o '"hash"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

                if [ -z "$HASH" ]; then
                    echo "❌ APK upload failed"
                    exit 1
                fi

                echo "$HASH" > apk_hash.txt
                echo "APK uploaded successfully"
                '''
            }
        }

        stage('Wait for MobSF Scan') {
            steps {
                sh '''
                echo "Waiting for MobSF analysis..."
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

                # Fetch FULL report (hidden)
                curl -s -X POST \
                  -H "X-Mobsf-Api-Key: ${MOBSF_API_KEY}" \
                  -d "hash=$HASH" \
                  ${MOBSF_URL}/api/v1/report_json \
                  > mobsf_report.json

                # Count vulnerabilities (summary only)
                VULN_COUNT=$(grep -o '"title"' mobsf_report.json | wc -l)

                echo "===== MobSF Security Summary ====="
                echo "APK Name : InsecureBankv2.apk"
                echo "Total Vulnerabilities : $VULN_COUNT"

                if [ "$VULN_COUNT" -gt 0 ]; then
                    echo "Security Gate : FAILED"
                    exit 1
                else
                    echo "Security Gate : PASSED"
                fi
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'mobsf_report.json, apk_hash.txt', fingerprint: true
        }
        success {
            echo '✅ PIPELINE PASSED – Application is secure'
        }
        failure {
            echo '❌ PIPELINE FAILED – View MobSF report in Artifacts'
        }
    }
}
