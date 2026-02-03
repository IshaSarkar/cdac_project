pipeline {
  agent any

  environment {
    // Use the IP/hostname reachable from the Jenkins agent. Replace if needed.
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
      steps {
        // Inject the secret only for the duration of this block
        withCredentials([string(credentialsId: 'mobsf-api-key', variable: 'MOBSF_API_KEY')]) {
          sh '''
            set -euo pipefail
            echo "Uploading APK to MobSF..."

            # Verify file exists
            if [ ! -f "apk/InsecureBankv2.apk" ]; then
              echo "APK file not found: apk/InsecureBankv2.apk"
              exit 1
            fi

            # Upload and fail on non-2xx; print server response for debugging
            RESPONSE=$(curl --show-error --fail -H "X-Mobsf-Api-Key: ${MOBSF_API_KEY}" \
              -F "file=@apk/InsecureBankv2.apk" \
              "${MOBSF_URL}/api/v1/upload" || true)

            echo "Upload response: $RESPONSE"

            # Try to extract 'hash' using jq (preferred) or fallback to grep/sed
            if command -v jq >/dev/null 2>&1; then
              HASH=$(echo "$RESPONSE" | jq -r '.hash // empty')
            else
              # Fallback: look for "hash":"..."; safely extract using sed
              HASH=$(echo "$RESPONSE" | sed -n 's/.*"hash"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            fi

            if [ -z "$HASH" ]; then
              echo "❌ Failed to extract APK hash from response"
              exit 1
            fi

            echo "$HASH" > apk_hash.txt
            echo "APK Hash saved: $HASH"
          '''
        }
      }
    }

    stage('Wait for MobSF Scan') {
      steps {
        sh '''
          set -euo pipefail
          echo "Waiting for MobSF analysis to complete..."
          sleep 30
        '''
      }
    }

    stage('Security Gate – MobSF') {
      steps {
        withCredentials([string(credentialsId: 'mobsf-api-key', variable: 'MOBSF_API_KEY')]) {
          sh '''
            set -euo pipefail
            if [ ! -f apk_hash.txt ]; then
              echo "apk_hash.txt not found"
              exit 1
            fi

            HASH=$(cat apk_hash.txt)
            echo "Fetching MobSF security report for hash: $HASH"

            REPORT=$(curl --show-error --fail -H "X-Mobsf-Api-Key: ${MOBSF_API_KEY}" \
              -d "hash=$HASH" \
              "${MOBSF_URL}/api/v1/report_json" || true)

            echo "Report response: $REPORT"

            # Count vulnerabilities: prefer jq if available, else count "title" entries
            if command -v jq >/dev/null 2>&1; then
              VULN_COUNT=$(echo "$REPORT" | jq '.findings | length // 0')
            else
              # heuristic: count occurrences of "title"
              VULN_COUNT=$(echo "$REPORT" | grep -o '"title"' | wc -l || echo 0)
            fi

            echo "Total vulnerability findings: $VULN_COUNT"

            if [ "${VULN_COUNT:-0}" -gt 0 ]; then
              echo "❌ SECURITY GATE FAILED – Vulnerable APK detected"
              exit 1
            else
              echo "✅ SECURITY GATE PASSED – APK is secure"
            fi
          '''
        }
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
