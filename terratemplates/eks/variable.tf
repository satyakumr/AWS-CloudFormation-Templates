variable "eks_cluster_role" {
  default = "EKSClusterRole"
}

variable "eks_cluster_name" {
  default = "Khosla-test"
}

variable "master_version" {
  default = "1.17"
}

variable "node_group_name" {
  default = "Khosla-test-nodes"
}

variable "eks_node_group" {
  default = "EKSNodesRole"
}

variable "node_instances_type" {}

variable "nodes_disk_size" {
  default = 10
}

variable "nodes_ssh_key" {}

variable "alb_name" {
  default = "Khosla-ALB"
}

variable "target_group_name" {
  default = "application-tg"
}

variable "certificate_arn" {
  default = "arn:aws:acm:ap-south-1:146776836293:certificate/8775dcfe-8e3b-42d1-94f6-97d8f9ad36c6"
}

variable "uatprivate-subnets" {}

variable "uatvpc" {}
