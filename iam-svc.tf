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


resource "aws_iam_policy" "appmesh_policy" {
  name        = "AppMesh-IAM"
  description = "IAM policy for AppMesh"
  path        = var.iam_role_path

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
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
          "appmesh:DeleteVirtualGateway"
        ]
        Resource = "*"
      },
      {
        Effect    = "Allow"
        Action    = ["iam:CreateServiceLinkedRole"]
        Resource  = "arn:aws:iam::*:role/aws-service-role/appmesh.amazonaws.com/AWSServiceRoleForAppMesh"
        Condition = {
          StringLike: {
            "iam:AWSServiceName" : ["appmesh.amazonaws.com"]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = [
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "acm-pca:DescribeCertificateAuthority",
          "acm-pca:ListCertificateAuthorities"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
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
          "route53:DeleteHealthCheck"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "appmesh_role" {
  name               = "appmesh-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::373346310182:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/37E176AEE22E1343BDD9631E150AAD9A"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "oidc.eks.us-east-1.amazonaws.com/id/37E176AEE22E1343BDD9631E150AAD9A:aud": "sts.amazonaws.com",
            "oidc.eks.us-east-1.amazonaws.com/id/37E176AEE22E1343BDD9631E150AAD9A:sub": "system:serviceaccount:appmesh-system:appmesh-controller"
          }
        }
      }
    ]
  })

  permissions_boundary = var.iam_role_permissions_boundary
}
