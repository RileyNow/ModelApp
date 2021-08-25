pipeline {
  agent any
  stages {
    stage('Git') {
      steps {
        echo 'Build'
        git(url: 'https://github.com/RileyNow/ModelApp', poll: true, branch: 'main')
      }
    }

    stage('ConfigUpload') {
      steps {
        echo 'Start Build...'
        sh '''cd CLUtilityScripts/
chmod 777 uploadToComponent.sh
bash ./uploadToComponent.sh Ben-ModelApp Payment data/component1.json false
bash ./uploadToComponent.sh Ben-ModelApp Wrapper data/wrapper.props false'''
      }
    }

    stage('Testing') {
      parallel {
        stage('Testing') {
          steps {
            echo 'Testing Start'
          }
        }

        stage('JUNIT') {
          steps {
            echo 'Junit'
          }
        }

        stage('Regression') {
          steps {
            echo 'Regression Scripts'
          }
        }

      }
    }

    stage('Build') {
      steps {
        echo 'Build'
      }
    }

    stage('Test Env Deploy') {
      steps {
        echo 'Deploy to UAT'
        sh '''cd CLUtilityScripts/
chmod 777 uploadToComponent.sh
bash ./exportAllData.sh Ben-ModelApp Test-UK json'''
      }
    }

    stage('Functional') {
      parallel {
        stage('Functional') {
          steps {
            echo 'Functional Test Start'
          }
        }

        stage('Selenium API') {
          steps {
            echo 'Selenium API Start'
          }
        }

      }
    }

    stage('PRD') {
      steps {
        echo 'PRD Deploy'
      }
    }

  }
}