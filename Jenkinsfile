pipeline {
  agent any

  environment {
    IMAGE = "darknessuuuu/todo-flask:${env.BUILD_NUMBER}"
  }

  stages {
    stage("Checkout") {
      steps {
        git url: 'https://github.com/AdamchDarkness/Todo.git', branch: 'main'
      }
    }

    stage("Install Python Dependencies") {
      steps {
        dir('app') {
          sh 'python3 -m pip install --upgrade pip'
          sh 'pip3 install -r requirements.txt'
        }
      }
    }

    stage("Build Docker") {
      steps {
        dir('app') {
          sh "docker build -t ${IMAGE} ."
        }
      }
    }

    stage("Push to DockerHub") {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${IMAGE}
          '''
        }
      }
    }

    stage("Deploy to Kubernetes") {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          sh 'kubectl apply -f k8s/deployment.yaml'
          sh 'kubectl apply -f k8s/service.yaml'
          sh 'kubectl apply -f k8s/pvc.yaml'
          sh 'kubectl apply -f k8s/secret.yaml'
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
