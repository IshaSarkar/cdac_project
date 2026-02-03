pipeline {
    agent any

    environment {
        // FIX 1: Use the direct IP address that worked in your manual curl tests
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
                // Ensure this ID matches your Jenkins Credentials (e.g., mobsf-api-key)
                MOBSF_API_KEY = credentials('mobsf-api-key')
            }
            steps {
                sh '''
                echo "Uploading APK to MobSF..."

                # FIX 2: Added -H "X-Mobsf-Api-Key" which MobSF prefers over standard "Authorization"
                # FIX 3: Added -v for visibility if it fails again
                RESPONSE=$(curl -s -X POST \
                  -H "X-Mobsf-Api-Key: ${MOBSF_API_KEY}" \
                  -F "file=@apk/InsecureBankv2.apk" \
                  ${MOBSF_URL}/api/v1/upload)

                echo "Upload response:"
                echo "$RESPONSE"

                HASH=$(echo "$RESPONSE" | grep -o '"hash"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

                if [ -z "$HASH" ]; then
                    echo "❌ Failed to extract APK hash - check your API Key and Network"
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
            }
            steps {
                sh '''
                if [ ! -f apk_hash.txt ]; then
                    echo "❌ apk_hash.txt not found!"
                    exit 1
                fi

                HASH=$(cat apk_hash.txt)
                echo "Fetching MobSF security report for hash: $HASH"

                # FIX 4: Used X-Mobsf-Api-Key header here as well
                REPORT=$(curl -s -X POST \
                  -H "X-Mobsf-Api-Key: ${MOBSF_API_KEY}" \
                  -d "hash=$HASH" \
                  ${MOBSF_URL}/api/v1/report_json)

                # Count vulnerabilities
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
            echo '❌ PIPELINE FAILED – Check logs for errors'
        }
    }
}
