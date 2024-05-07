provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
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
