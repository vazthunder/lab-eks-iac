variable "project"             { type = string }
variable "env"                 { type = string }
variable "vpc_id"              { type = string }
variable "subnet-private-a_id" { type = string }
variable "subnet-private-b_id" { type = string }
variable "master_role_name"    { type = string }
variable "code_source"         { type = string }
variable "code_repository"     { type = string }
variable "code_branch"         { type = string }
variable "build_compute_type"  { type = string }
variable "build_image"         { type = string }
variable "build_timeout"       { type = string }