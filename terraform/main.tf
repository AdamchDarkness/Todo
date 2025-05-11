terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

provider "virtualbox" {}

locals {
  template_ova = "${path.module}/ubuntu-template.ova"

  ssh_user     = "vagrant"
  ssh_key_path = "C:/Users/PC/.ssh/id_rsa"
  host_if      = "VirtualBox Host-Only Ethernet Adapter"
}

resource "virtualbox_vm" "jenkins" {
  name   = "jenkins-vm"
  image  = local.template_ova
  cpus   = 2
  memory = "2048 MB"

  network_adapter {
    type           = "hostonly"
    host_interface = local.host_if
    ipv4_address   = "192.168.56.1"
  }

  network_adapter {
    type = "nat"
  }
}

resource "virtualbox_vm" "k8s" {
  name   = "k8s-vm"
  image  = local.template_ova
  cpus   = 2
  memory = "4096 MB"

  network_adapter {
    type           = "hostonly"
    host_interface = local.host_if
    ipv4_address   = "192.168.56.4"
  }

  network_adapter {
    type = "nat"
  }
}

resource "null_resource" "ansible_provision" {
  # on attend que les deux VMs soient créées
  depends_on = [
    virtualbox_vm.jenkins,
    virtualbox_vm.k8s,
  ]

  provisioner "local-exec" {
    command = <<EOT
      # passe en UTF-8 pour éviter les pb Windows→Bash
      chcp 65001

      # installez Ansible / git si ce n'est déjà fait :
      #   pip install ansible

      # clonez ou mettez à jour votre repo Ansible
      if [ ! -d ansible ]; then
        git clone https://github.com/VOTRE_COMPTE/votre-ansible-repo.git ansible
      else
        cd ansible && git pull && cd ..
      fi

      # lance le playbook avec l’inventaire statique
      ansible-playbook -i inventory.ini playbook.yml \
        --private-key="${local.ssh_key_path}" \
        --user="${local.ssh_user}"
    EOT

    # pour que Terraform exécute via PowerShell
    interpreter = ["PowerShell", "-Command"]
  }
}

output "jenkins_ip" {
  value = virtualbox_vm.jenkins.network_adapter[0].ipv4_address
}
output "k8s_ip" {
  value = virtualbox_vm.k8s.network_adapter[0].ipv4_address
}
