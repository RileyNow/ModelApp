pipeline {
  agent any
  stages {
    stage('Git') {
      steps {
        echo 'Build'
        git(url: 'https://github.com/RileyNow/ModelApp', poll: true, branch: 'main')
      }
    }

  }
}