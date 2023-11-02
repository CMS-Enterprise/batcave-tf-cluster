output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The version of the cluster being deployed"
  value       = var.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
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
  value       = try(module.eks.cluster_certificate_authority_data, "")
}

output "cluster_id" {
  description = "[deprecated, use cluster_name] The name of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_name
}

output "cluster_name" {
  description = "The name of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_name
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
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
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
# Self Managed Node Group
################################################################################

output "self_managed_node_groups" {
  description = "Map of attribute maps for all self managed node groups created"
  value       = module.eks.self_managed_node_groups
}

output "eks_managed_node_group" {
  description = "ARNs of all self managed node groups created"
  value       = flatten(module.eks_managed_node_groups)
}

################################################################################
# Additional
################################################################################

output "aws_auth_configmap_yaml" {
  value = module.eks.aws_auth_configmap_yaml
}

output "cosign_iam_role_arn" {
  value = try(aws_iam_role.cosign[0].arn, "")
}

################################################################################
# AWS Load Balancer
################################################################################

output "batcave_lb_dns" {
  description = "DNS value of NLB created for routing traffic to apps"
  value       = aws_lb.batcave_alb.dns_name
}

output "private_alb_security_group_id" {
  description = "The Security Group that controls access to the private ALB"
  value       = aws_security_group.batcave_alb.id
}

output "batcave_alb_proxy_dns" {
  description = "DNS value of ALB created for proxying request"
  value       = var.create_alb_proxy ? aws_lb.batcave_alb_proxy[0].dns_name : ""
}

output "batcave_alb_shared_dns" {
  description = "DNS value of ALB created for proxying requests through an ALB in the shared subnet"
  value       = var.create_alb_shared ? aws_lb.batcave_alb_shared[0].dns_name : ""
}
