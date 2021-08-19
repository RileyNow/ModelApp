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
        sh '''#!/usr/bin/env bash
bash ./uploadToComponent.sh Ben-ModelApp Payment data/component1.json false
'''
      }
    }

  }
}