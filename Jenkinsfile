pipeline {
  agent any
  stages {
    stage('Git') {
      steps {
        echo 'Build'
        git(url: 'https://github.com/RileyNow/ModelApp', poll: true, branch: 'main')
      }
    }

    stage('error') {
      steps {
        echo 'Start Build...'
        sh '''cd CLUtilityScripts/
chmod 777 uploadToComponent.sh
bash ./uploadToComponent.sh Ben-ModelApp Payment data/component1.json false'''
      }
    }

  }
}