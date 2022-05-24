output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "worker_iam_role_arn" {
  value = module.eks.self_managed_node_groups.general.iam_role_arn
}

output "worker_iam_role_name" {
  value = module.eks.self_managed_node_groups.general.iam_role_name
}

output "general_node_pool_launch_template" {
  value = module.eks.self_managed_node_groups.general.launch_template_id
}

# output "bootstrap_node_pool_launch_template" {
#   value = module.eks.self_managed_node_groups.bootstrap.launch_template_id
# }

# output "memory_node_pool_launch_template" {
#   value = module.eks.self_managed_node_groups.memory.launch_template_id
# }

# output "cpu_node_pool_launch_template" {
#   value = module.eks.self_managed_node_groups.cpu.launch_template_id
# }
output "provider_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "worker_security_group_id" {
  value = module.eks.node_security_group_id
}

################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = try(module.eks.arn, "")
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = try(module.eks.certificate_authority[0].data, "")
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = try(module.eks.identity[0].oidc[0].issuer, "")
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = try(module.eks.platform_version, "")
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = try(module.eks.status, "")
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = try(module.eks.cluster_primary_security_group_id, "")
}

################################################################################
# Cluster Security Group
################################################################################

output "cluster_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = try(module.eks.aws_security_group.cluster[0].arn, "")
}

################################################################################
# Node Security Group
################################################################################

output "node_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the node shared security group"
  value       = try(module.eks.aws_security_group.node[0].arn, "")
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = try(module.eks.aws_security_group.node[0].id, "")
}

################################################################################
# IRSA
################################################################################

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = var.enable_irsa ? concat(aws_iam_openid_connect_provider.oidc_provider[*].arn, [""])[0] : null
}

################################################################################
# IAM Role
################################################################################

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = try(module.eks.aws_iam_role.this[0].name, "")
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = try(module.eks.aws_iam_role.this[0].arn, "")
}

output "cluster_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = try(module.eks.ws_iam_role.this[0].unique_id, "")
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = try(module.eks.aws_cloudwatch_log_group.this[0].name, "")
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = try(module.eks.aws_cloudwatch_log_group.this[0].arn, "")
}

################################################################################
# Fargate Profile
################################################################################

output "fargate_profiles" {
  description = "Map of attribute maps for all EKS Fargate Profiles created"
  value       = module.eks.fargate_profiles
}

################################################################################
# EKS Managed Node Group
################################################################################

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

################################################################################
# Self Managed Node Group
################################################################################

output "self_managed_node_groups" {
  description = "Map of attribute maps for all self managed node groups created"
  value       = module.eks.self_managed_node_groups
}

################################################################################
# Launch template
################################################################################

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = module.eks.self_managed_node_groups.general.launch_template_id
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = module.eks.self_managed_node_groups.general.launch_template_arn
  #  value       = try(aws_launch_template.this[0].arn, "")
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = module.eks.self_managed_node_groups.general.launch_template_latest_version
  #  value       = try(aws_launch_template.this[0].latest_version, "")
}

################################################################################
# Additional
################################################################################

output "aws_auth_configmap_yaml" {
  value = module.eks.aws_auth_configmap_yaml
}

################################################################################
# AWS Load Balancer
################################################################################
output "self_managed_node_group_general" {
  value = module.eks.self_managed_node_groups.general.launch_template_id
}

output "self_managed_node_group_gitlab_runners" {
  value = module.eks.self_managed_node_groups.gitlab-runners.launch_template_id
}

output "general_nodepool_asg" {
  value = module.eks.self_managed_node_groups.general.autoscaling_group_id
}

output "runner_nodepool_asg" {
  value = module.eks.self_managed_node_groups.gitlab-runners.autoscaling_group_id
}

output "batcave_lb_dns" {
  description = "DNS value of NLB created for routing traffic to apps"
  value       = aws_lb.batcave_nlb.dns_name
}

output "batcave_transport_proxy_lb_dns" {
  description = "DNS value of NLB created for proxying requests through the transport subnet"
  value       = var.create_transport_proxy_lb ? aws_lb.batcave_transport[0].dns_name : ""
}
