# data "aws_iam_policy_document" "test_assume_role_policy" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["eks-fargate-pods.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "test_iam_role" {

#   name        = 
#   name_prefix = 
#   path        = var.iam_role_path
#   description = var.iam_role_description

#   assume_role_policy    = data.aws_iam_policy_document.assume_role_policy[0].json
#   permissions_boundary  = var.iam_role_permissions_boundary
#   force_detach_policies = true

#   tags = merge(var.tags, var.iam_role_tags)
# }

# resource "aws_iam_role_policy_attachment" "this" {
#   for_each = { for k, v in toset(compact([
#     "${local.iam_role_policy_prefix}/AmazonEKSFargatePodExecutionRolePolicy",
#     var.iam_role_attach_cni_policy ? local.cni_policy : "",
#   ])) : k => v if var.create && var.create_iam_role }

#   policy_arn = each.value
#   role       = aws_iam_role.this[0].name
# }

# resource "aws_iam_role_policy_attachment" "additional" {
#   for_each = { for k, v in var.iam_role_additional_policies : k => v if var.create && var.create_iam_role }

#   policy_arn = each.value
#   role       = aws_iam_role.this[0].name
# }

data "aws_iam_policy_document" "appmesh_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "appmesh_role" {
  name        = "app_mesh"
  path        = var.iam_role_path
  description = " App Mesh role"

  assume_role_policy    = data.aws_iam_policy_document.appmesh_trust_policy.json
  max_session_duration  = var.max_session_duration
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = var.force_detach_policies

  tags = var.tags
}

data "aws_iam_policy_document" "appmesh_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "appmesh:ListVirtualRouters",
      "appmesh:ListVirtualServices",
      "appmesh:ListRoutes",
      "appmesh:ListGatewayRoutes",
      "appmesh:ListMeshes",
      "appmesh:ListVirtualNodes",
      "appmesh:ListVirtualGateways",
      "appmesh:DescribeMesh",
      "appmesh:DescribeVirtualRouter",
      "appmesh:DescribeRoute",
      "appmesh:DescribeVirtualNode",
      "appmesh:DescribeVirtualGateway",
      "appmesh:DescribeGatewayRoute",
      "appmesh:DescribeVirtualService",
      "appmesh:CreateMesh",
      "appmesh:CreateVirtualRouter",
      "appmesh:CreateVirtualGateway",
      "appmesh:CreateVirtualService",
      "appmesh:CreateGatewayRoute",
      "appmesh:CreateRoute",
      "appmesh:CreateVirtualNode",
      "appmesh:UpdateMesh",
      "appmesh:UpdateRoute",
      "appmesh:UpdateVirtualGateway",
      "appmesh:UpdateVirtualRouter",
      "appmesh:UpdateGatewayRoute",
      "appmesh:UpdateVirtualService",
      "appmesh:UpdateVirtualNode",
      "appmesh:DeleteMesh",
      "appmesh:DeleteRoute",
      "appmesh:DeleteVirtualRouter",
      "appmesh:DeleteGatewayRoute",
      "appmesh:DeleteVirtualService",
      "appmesh:DeleteVirtualNode",
      "appmesh:DeleteVirtualGateway",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "appmesh_policy" {
  name   = "appmesh_policy"
  path        = var.iam_role_path
  policy = data.aws_iam_policy_document.appmesh_policy.json
}

resource "aws_iam_role_policy_attachment" "appmesh_policy_attachment" {
  role       = aws_iam_role.appmesh_role.name
  policy_arn = aws_iam_policy.appmesh_policy.arn
}

data "aws_iam_policy_document" "appmesh_support_policy" {
  statement {
    effect   = "Allow"
    actions  = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:aws:iam::*:role/aws-service-role/appmesh.amazonaws.com/AWSServiceRoleForAppMesh"]
    condition {
      test = "StringLike"
      variable = "iam:AWSServiceName"
      values = ["appmesh.amazonaws.com"]
    }
  }

  statement {
    effect   = "Allow"
    actions  = [
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "acm-pca:DescribeCertificateAuthority",
      "acm-pca:ListCertificateAuthorities",
    ]
    resources = ["*"]
  }

  statement {
    effect   = "Allow"
    actions  = [
      "servicediscovery:CreateService",
      "servicediscovery:DeleteService",
      "servicediscovery:GetService",
      "servicediscovery:GetInstance",
      "servicediscovery:RegisterInstance",
      "servicediscovery:DeregisterInstance",
      "servicediscovery:ListInstances",
      "servicediscovery:ListNamespaces",
      "servicediscovery:ListServices",
      "servicediscovery:GetInstancesHealthStatus",
      "servicediscovery:UpdateInstanceCustomHealthStatus",
      "servicediscovery:GetOperation",
      "route53:GetHealthCheck",
      "route53:CreateHealthCheck",
      "route53:UpdateHealthCheck",
      "route53:ChangeResourceRecordSets",
      "route53:DeleteHealthCheck",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "appmesh_support_policy" {
  name   = "appmesh_support_policy"
  path        = var.iam_role_path
  policy = data.aws_iam_policy_document.appmesh_support_policy.json
}

resource "aws_iam_role_policy_attachment" "appmesh_support_policy_attachment" {
 role = aws_iam_role.appmesh_role.name
 policy_arn = aws_iam_policy.appmesh_support_policy.arn
}

resource "kubernetes_service_account" "appmesh_service_account" {
  metadata {
    name = "appmesh-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.appmesh_role.arn
    }
  }
}
