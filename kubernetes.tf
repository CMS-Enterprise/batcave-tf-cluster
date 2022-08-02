provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

locals {
  configmap_roles = [ for k,v in module.eks.self_managed_node_groups : {
      rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${v.iam_role_name}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = tolist(concat(
        [
          "system:bootstrappers",
          "system:nodes",
        ],
      ))
    }
  ]
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
        local.configmap_roles
      ))
    )
  }
  depends_on = [module.eks]
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
  depends_on = [module.eks]
}
