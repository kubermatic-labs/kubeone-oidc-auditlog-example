output "kubeone_api" {
  description = "kube-apiserver LB endpoint"

  value = {
    endpoint = var.lb_apiserver
  }
}

output "kubeone_hosts" {
  description = "Control plane endpoints to SSH to"

  value = {
    control_plane = {
      cluster_name         = var.cluster_name
      cloud_provider       = "hetzner"
      private_address      = hcloud_server_network.control_plane.*.ip
      public_address       = hcloud_server.control_plane.*.ipv4_address
      network_id           = hcloud_network.net.id
      ssh_agent_socket     = var.ssh_agent_socket
      ssh_port             = var.ssh_port
      ssh_private_key_file = var.ssh_private_key_file
      ssh_user             = var.ssh_username
    }
  }
}

output "kubeone_workers" {
  description = "Workers definitions, that will be transformed into MachineDeployment object"

  value = {
    # following outputs will be parsed by kubeone and automatically merged into
    # corresponding (by name) worker definition
    "${var.cluster_name}-workers" = {
      replicas = var.workers_replicas
      providerSpec = {
        sshPublicKeys   = [file(var.ssh_public_key_file)]
        operatingSystem = var.worker_os
        operatingSystemSpec = {
          distUpgradeOnBoot = false
        }
        cloudProviderSpec = {
          # provider specific fields:
          # see example under `cloudProviderSpec` section at:
          # https://github.com/kubermatic/machine-controller/blob/master/examples/hetzner-machinedeployment.yaml
          image      = var.image
          serverType = var.worker_type
          location   = var.datacenter
          networks = [
            hcloud_network.net.id
          ]
          # Datacenter (optional)
          # datacenter = ""
          labels = {
            "${var.cluster_name}-workers" = "workers",
            "keep"                        = "true"
          }
        }
      }
    }
  }
}
