
#################################################################################
# Access Entry for Cluster access
#################################################################################
## The resources  access entry and policy association is targeting roles that require cluster admins permissions
## it can be repeated for roles that require different cluster policy
resource "aws_eks_access_entry" "cluster_admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name      = local.name
  kubernetes_groups = []
  principal_arn     = each.value
  type              = "STANDARD"
  user_name         = try(each.value.user_name, null)

  depends_on = [
    module.eks_managed_node_groups,
  ]
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  for_each = toset(var.admin_principal_arns)

  access_scope {
    namespaces = []
    type       = "cluster"
  }

  cluster_name = local.name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  depends_on = [
    aws_eks_access_entry.cluster_admin,
  ]
}

## The resources  access entry and policy association is targeting roles that require cluster Admin ReadOnly Permissions
resource "aws_eks_access_entry" "cluster_admin_readonly" {
  for_each = toset(var.admin_readonly_principal_arns)

  cluster_name      = local.name
  kubernetes_groups = []
  principal_arn     = each.value
  type              = "STANDARD"
  user_name         = try(each.value.user_name, null)

  depends_on = [
    module.eks_managed_node_groups,
  ]
}

resource "aws_eks_access_policy_association" "cluster_admin_readonly" {
  for_each = toset(var.admin_readonly_principal_arns)

  access_scope {
    namespaces = []
    type       = "cluster"
  }

  cluster_name = local.name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
  principal_arn = each.value

  depends_on = [
    aws_eks_access_entry.cluster_admin_readonly,
  ]
}

## Creating access entry for delete_ebs_volumes_lambda with namespaced adminpolicy
resource "aws_eks_access_entry" "delete_ebs_volume" {
  count             = var.delete_ebs_volume_role_arn != "" ? 1 : 0
  cluster_name      = local.name
  kubernetes_groups = []
  principal_arn     = var.delete_ebs_volume_role_arn
  type              = "STANDARD"
  user_name         = (null)

  depends_on = [
    module.eks_managed_node_groups,
    kubectl_manifest.batcave_namespace
  ]
}
resource "aws_eks_access_policy_association" "delete_ebs_volume" {
  count = var.delete_ebs_volume_role_arn != "" ? 1 : 0
  access_scope {
    namespaces = ["batcave"]
    type       = "namespace"
  }

  cluster_name = local.name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = var.delete_ebs_volume_role_arn

  depends_on = [
    aws_eks_access_entry.delete_ebs_volume,
  ]
}
