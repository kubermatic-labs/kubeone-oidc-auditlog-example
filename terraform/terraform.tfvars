cluster_name = "example"

# use larger workers with 4 CPU + 8GB RAM
worker_type      = "cpx31"
initial_machinedeployment_replicas = 1

apiserver_alternative_names = ["controlplane.example.com"]
