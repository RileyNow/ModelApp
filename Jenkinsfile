pipeline {
  agent any
  stages {
    stage('Git') {
      steps {
        echo 'Build'
        git(url: 'https://github.com/RileyNow/ModelApp', poll: true, branch: 'main')
      }
    }

    stage('') {
      steps {
        echo 'Start Build...'
        sh './uploadToComponent.sh Ben-ModelApp Payment data/component1.json false'
      }
    }

  }
}