pipeline {
 HEAD
  agent any

  stages {
    stage('Build Docker Image') {
      steps {
        sh 'docker build -t devsecops-app .'
      }
    }

    stage('Deploy to Swarm') {
      steps {
        sh '''
        docker service rm devsecops_service || true
        docker service create --name devsecops_service -p 5000:5000 devsecops-app
        '''
      }
    }
  }
}
