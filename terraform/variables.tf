variable "region"                { type = string }
variable "project"               { type = string }
variable "env"                   { type = string }
variable "cidr_vpc"              { type = string }
variable "cidr_private_a"        { type = string }
variable "cidr_private_b"        { type = string }
variable "cidr_public_a"         { type = string }
variable "cidr_public_b"         { type = string }
variable "cidr_cluster"          { type = string }
variable "bastion_ami_id"        { type = string }
variable "bastion_instance_type" { type = string }
variable "bastion_storage_size"  { type = string }
variable "worker_instance_type"  { type = string }
variable "worker_capacity_type"  { type = string }
variable "worker_storage_size"   { type = string }
variable "worker_initial_size"   { type = string }
variable "worker_max_size"       { type = string }
variable "worker_min_size"       { type = string }
variable "key_name"              { type = string }
variable "code_source"           { type = string }
variable "code_repository"       { type = string }
variable "code_branch"           { type = string }
variable "build_compute_type"    { type = string }
variable "build_image"           { type = string }
variable "build_timeout"         { type = string }
