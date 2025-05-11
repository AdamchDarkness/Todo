# Todo

Ce dépôt contient :

- **Infrastructure as Code** avec Terraform (création de VMs VirtualBox) + Ansible (provisionnement logiciel)  
- **Application Web** TODO list en Flask  
- **Pipeline Jenkins** complet (build, tests, Docker, push, déploiement)  
- **Manifests Kubernetes** pour déployer sur un cluster local  
- **Gestion Git** : structure, branches, Pull Request, hooks  
- **Documentation** (ce README)

## 1. Provisionnement de l’infrastructure

### Terraform

1. Installez Terraform & VirtualBox.  
2. Allez dans `terraform/` :  
   ```bash
   cd terraform
   terraform init
   terraform apply -auto-approve
   ```
 3.Deux VMs sont créées :
  - jenkins-vm (192.168.56.1)
  - k8s-vm (192.168.56.4)

### Ansible
1. Installez Ansible.
2. Depuis la racine du repo :
  ```bash
  ansible-playbook -i ansible/inventory.ini ansible/playbook.yml \ 
  --private-key=~/.ssh/id_rsa --user=vagrant
    ```
3. Ansible installe Docker, Jenkins, Kubernetes (kubeadm + Flannel) sur les VMs.

## 2. Application Web
- Tech : Python 3.10, Flask 2.x
- Fonctionnalités : TODO list (affichage, ajout, suppression)
- Lancer localement :
   ``bash
   cd app
   python3 -m pip install -r requirements.txt
   FLASK_APP=app.py flask run
  ```
- Accessible sur http://localhost:5000.

## 3. Pipeline Jenkins
   - Fichier : Jenkinsfile (Declarative Pipeline)
   - Etaps :
      - Check repo
      - Installation dépendances Python
      - Build de l’image Docker (darknessuuuu/todo-flask:${BUILD_NUMBER})
      - Push sur Docker Hub (credential dockerhub-creds)
      - Deploy sur k8s (kubectl apply -f k8s/..., credential kubeconfig)
   - Configurer Jenkins :
      - Installer Docker Pipeline Plugin
      - Ajouter credentials : dockerhub-creds / kubeconfig
   - Créer un job Pipeline pointant sur ce Jenkinsfile.

## 4. Déploiement Kubernetes
   Fournis dans k8s/ :
      ```bash
      - pvc.yaml : PersistentVolumeClaim 1 Gi 
      - secret.yaml : secret FLASK_ENV=prod (Base64) 
      - deployment.yaml : Deployment 1 réplique, volume + secret injecté 
      - service.yaml : Service NodePort exposé sur le port 30080 \
      ```
   Appliquer
      ```bash
      export KUBECONFIG=~/.kube/config
      kubectl apply -f k8s/pvc.yaml
      kubectl apply -f k8s/secret.yaml
      kubectl apply -f k8s/deployment.yaml
      kubectl apply -f k8s/service.yaml
       ```
## 5. Déploiement Kubernetes
   - Branches:
      - main → code stable
      - dev → développement
   - Pull Request :
      - Créez une PR dev → main pour validation des changements
   - Hooks :
      - .git/hooks/pre-commit pour lancer un linter Python avant commit
   - Commandes
    ```bash 
    # branche main
    git checkout main
    git pull origin main

    # aller sur branche dev
    git checkout -b dev

    # push sur depot distant
    git push -u origin dev

    #cree pr vers main
    gh pr create \
    --title "Merge dev into main" \
    --body "merge" \
    --base main \
    --head dev
    
    #Hook pre-commit
    cat > .git/hooks/pre-commit << 'EOF'
    #!/bin/sh
    echo "Lancement du linter"
    flake8 app
    if [ $? -ne 0 ]; then
    echo "Erreurs"
    exit 1
    fi
    EOF
    # liberer les permission
    chmod +x .git/hooks/pre-commit
    ```
