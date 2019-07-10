pipeline {
  environment {
    credentialsIdCredential = 'ansibleKey'
  }
  agent any
  stages {
    stage('run ansible deploy playbook') {
      steps {
        ansiblePlaybook (
          playbook: 'app.yml',
          credentialsId: credentialsIdCredential,
          )
      }
    }
  }
}
