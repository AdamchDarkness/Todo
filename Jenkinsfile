pipeline {
  agent any

  environment {
    IMAGE = "DOCKERHUB_USER/todo-flask:${env.BUILD_NUMBER}"
    CREDS = credentials('dockerhub-creds')
  }

  stages {
    stage("Checkout") {
      steps { git branch: 'dev', url: 'https://github.com/DOCKERHUB_USER/todo-flask.git' }
    }

    stage("Unit Tests") {
      steps {
        sh 'pip install -r requirements.txt'
        sh 'pytest --maxfail=1 --disable-warnings -q'
      }
    }

    stage("Build Docker") {
      steps { sh "docker build -t ${IMAGE} ." }
    }

    stage("Push to DockerHub") {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                          usernameVariable: 'U', passwordVariable: 'P')]) {
          sh 'echo $P | docker login -u $U --password-stdin'
          sh "docker push ${IMAGE}"
        }
      }
    }

    stage("Deploy to Kubernetes") {
      steps {
        sh 'kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml'
      }
    }
  }

  post {
    always { cleanWs() }
  }
}
