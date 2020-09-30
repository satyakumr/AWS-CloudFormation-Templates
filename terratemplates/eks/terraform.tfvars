eks_cluster_role  = "EKSClusterRole"
eks_cluster_name  = "Khosla-test"
master_version    = "1.17"
node_group_name   = "Khosla-test-nodes"
eks_node_group    = "EKSNodeRole"
nodes_disk_size   = 10
alb_name          = "Khosla-ALB"
target_group_name = "application-tg"
certificate_arn   = "arn:aws:acm:ap-south-1:146776836293:certificate/8775dcfe-8e3b-42d1-94f6-97d8f9ad36c6"

