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

variable "project_id" {
  type    = string
}

variable "builder_sa" {
  type = string
}

source "googlecompute" "gcp_ubuntu" {
  project_id          = var.project_id
  zone                = "us-central1-f"
  source_image_family = "ubuntu-2204-lts"
  machine_type        = "n2-standard-4"
  network             = "tutorial"
  subnetwork          = "tutorial"
  omit_external_ip    = true
  use_internal_ip     = true
  disk_size           = "100"
  ssh_username        = "ubuntu"
  impersonate_service_account = var.builder_sa
}

build {
  name                = "compute-image"

  source "source.googlecompute.gcp_ubuntu" {
    image_family        = "ubuntu-2204-compute-image"
    image_name          = "ubuntu-2204-compute-image-{{timestamp}}"
    image_description   = "compute image"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo bash -c '{{ .Vars }} {{ .Path }}'"
    scripts         = fileset(".", "scripts-ubuntu-22.04/*")
  }
}
