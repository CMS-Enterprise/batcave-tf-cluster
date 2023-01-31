provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

locals {
  configmap_roles = [for k, v in module.eks.self_managed_node_groups : {
    rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${v.iam_role_name}"
    username = "system:node:{{EC2PrivateDNSName}}"
    groups = tolist([
      "system:bootstrappers",
      "system:nodes"
    ])
  }]
}

locals {
  aolytix_map_role = (var.aolytix_role_access ?
    ([{
      rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/aolytix-role",
      username = "aolytix-role",
      groups   = ["system:masters"]
    }]) :
  [])
}

locals {
  github_actions_map_role = (var.github_actions_role_access ?
    ([{
      rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/batcave-github-actions-role",
      username = "batcave-github-actions-role",
      groups   = ["system:masters"]
    }]) :
  [])
}


resource "kubernetes_cluster_role" "persistent_volume_management" {
  count = var.grant_delete_ebs_volumes_lambda_access ? 1 : 0

  metadata {
    name = "batcave:persistent-volume-management"
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["create", "delete", "get", "list", "update", "watch"]
  }
  depends_on = [null_resource.kubernetes_requirements]
}

locals {
  delete_ebs_volumes_lambda_subject_name = "batcave:persistent-volume-managers"
}
resource "kubernetes_cluster_role_binding" "delete_ebs_volumes_lambda" {
  count = var.grant_delete_ebs_volumes_lambda_access ? 1 : 0

  metadata {
    name = "batcave:persistent-volume-managers"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.persistent_volume_management[0].metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.delete_ebs_volumes_lambda_subject_name
  }
  depends_on = [null_resource.kubernetes_requirements]
}

locals {
  delete_ebs_volumes_lambda_role_mapping = (var.grant_delete_ebs_volumes_lambda_access ?
    ([{
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/delete_ebs_volumes_lambda_role",
      username = "batcave:delete-ebs-volumes-lambda",
      groups   = [local.delete_ebs_volumes_lambda_subject_name]
    }]) :
  [])
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = merge(
      {
        "app.kubernetes.io/managed-by" = "Terraform"
      }
    )
  }
  data = {
    mapRoles = yamlencode(
      distinct(concat(
        tolist(local.configmap_roles),
        tolist(local.aolytix_map_role),
        tolist(local.github_actions_map_role),
        tolist(local.delete_ebs_volumes_lambda_role_mapping)
      ))
    )
  }
  depends_on = [
    null_resource.kubernetes_requirements,
    kubernetes_cluster_role_binding.delete_ebs_volumes_lambda,
  ]
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

# Create the batcave namespace, but don't delete it upon destroy
# This is to work around an issue where dev clusters were prevented
# from deletion due to namespace cleanup taking too long.
# Ideally we would use kubernetes_namespace resource, but presently
# there is no way to ignore resource upon destroy.
# Ref: https://github.com/hashicorp/terraform/issues/3874
resource "kubectl_manifest" "batcave_namespace" {
  apply_only    = true
  ignore_fields = ["metadata.annotations", "metadata.labels"]
  yaml_body     = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: batcave
YAML
  depends_on    = [null_resource.kubernetes_requirements]
}
