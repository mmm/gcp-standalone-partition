#
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  num_compute_instances = 2
  default_instance_type = "n2-standard-4"

  #compute_os_image = "ubuntu-os-cloud/ubuntu-2204-lts"
  compute_os_image = "debian-cloud/debian-12"
  # or more generally in the form of projects/{project}/global/images/family/{family}
  #compute_os_image = "projects/cloud-hpc-image-public/global/images/family/hpc-centos-7"
  #compute_os_image = "projects/cloud-hpc-image-public/global/images/family/hpc-rocky-linux-8"
}

resource "google_compute_instance" "dev" {
  count        = local.num_compute_instances
  name         = "worker-node-${count.index}"
  machine_type = local.default_instance_type
  project      = var.project_id
  zone         = var.zone

  tags = var.tags

  boot_disk {
    initialize_params {
      image = local.compute_os_image
    }
  }

  # cannot stop instances that have nvme attachments, so just get rid of this
  # scratch_disk {
  #   interface = "NVME" # Note: check if your OS image requires additional drivers or config to optimize NVME performance
  # }

  metadata = {
    enable-oslogin = "TRUE"
  }

  network_interface {
    subnetwork = var.subnet
    subnetwork_project = var.project_id
    #access_config {} # public ephemeral IP... comment this out for private-only IPs
  }

  #metadata_startup_script = file("provision.sh")
  metadata_startup_script = templatefile("provision.sh.tmpl", {
    home_ip = var.home_volume_ip
    tools_ip = var.tools_volume_ip
  })

  service_account {
    #scopes = ["userinfo-email", "compute-ro", "storage-full"]
    scopes = ["cloud-platform"]  # too permissive for production
  }
}
