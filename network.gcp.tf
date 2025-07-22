module "project-gcp" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v40.0.0"
  name            = "weatherscanner-466411"

  project_reuse = {
    use_data_source = false
    project_attributes = {
      name   = "weatherscanner-466411"
      number = "886794755170"
    }
  }
  
  services = [
    "container.googleapis.com",  # Necessario per GKE
    "compute.googleapis.com", # Necessario per GKE
    "iam.googleapis.com", # Necessario per permessi progetto cloud
    "serviceusage.googleapis.com" # Necessario per GKE
  ]
}

module "vpc-gcp" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v40.0.0"
  project_id = module.project-gcp.project_id
  name       = "weatherscanner-vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "gke"
      region        = "europe-west8"
      secondary_ip_ranges = {
        pods     = "172.16.0.0/20"
        services = "192.168.0.0/24"
      }
    },
    {
      ip_cidr_range = "10.0.1.0/24"
      name          = "gke-cp"
      region        = "europe-west8"
    }
  ]
}

resource "local_file" "example-env-file" {
    filename = "../weather-scanner-crawler/.env"
  content = <<EOF
    test=${module.vpc_gcp.self_link}
  EOF
}

# module "cluster-gke" {
#   source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v40.0.0"
#   project_id = module.project-gcp.project_id
#   name       = "weather-scanner-gke"
#   location   = "europe-west8"
#   access_config = {
#     ip_access = {
#       private_endpoint_config = {
#         endpoint_subnetwork = module.vpc-gcp.subnet_ids["europe-west8/gke-cp"]
#         global_access       = false
#       }
#       authorized_ranges = {
#         internal-vms = "10.0.0.0/8"
#       }
#     }
#   }

#   vpc_config = {
#     network    = module.vpc-gcp.self_link
#     subnetwork = module.vpc-gcp.subnet_self_links["europe-west8/gke"]
#     secondary_range_names = {
#       pods     = "pods"
#       services = "services"
#     }
#   }
#   labels = {
#     environment = "dev"
#   }
# }