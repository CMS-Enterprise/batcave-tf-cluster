# IAM policy to access KMS key
# Get Arn for SOPS KMS policy
data "aws_kms_alias" "sops" {
  name = "alias/batcave-landing-sops"
}

data "aws_iam_policy_document" "node_policy" {
  statement {
    sid = "K8s-nodes"
    actions = [
      "kms:*",
    ]
    resources = [
      data.aws_kms_alias.sops.arn,
      data.aws_kms_alias.sops.target_key_arn,
    ]
  }
  statement {
    sid = "kmslist"
    actions = [
      "kms:List*",
      "kms:Describe*",
      "s3:*",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]
    resources = ["*"]
  }
}

# KMS policy to allow sops key only
resource "aws_iam_policy" "node_policy" {
  name        = "${local.name}-node_policy"
  path        = var.iam_role_path
  description = "IAM policy to nodes"
  policy      = data.aws_iam_policy_document.node_policy.json
}

# Attach KMS policy to node IAM role
resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = module.eks.self_managed_node_groups
  policy_arn = aws_iam_policy.node_policy.arn
  role       = each.value.iam_role_name
}

# Secrets Manager policy
resource "aws_iam_policy" "secretsmanager_policy" {
  name        = "${local.name}-secretsmanager-policy"
  path        = var.iam_role_path
  description = "IAM policy to access secretsm manager"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "secretsfullaccess",
        "Action" : [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}

# Attach secretsmanager policy to node IAM role
resource "aws_iam_role_policy_attachment" "secretsmanager" {
  for_each   = module.eks.self_managed_node_groups
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
  role       = each.value.iam_role_name
}


# Cloudwatch Logs policy
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid = "logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*",
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${local.name}-cloudwatchlogs-policy"
  path        = var.iam_role_path
  description = "IAM policy to access cloudwatch logs"
  policy      = data.aws_iam_policy_document.cloudwatch_logs.json
}

# Attach cloudwatchlogs policy to node IAM role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  for_each   = module.eks.self_managed_node_groups
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
  role       = each.value.iam_role_name
}
# SSM policy
resource "aws_iam_policy" "ssm_managed_instance" {
  name = "ssm-policy-${var.cluster_name}"
  path = var.iam_role_path
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        Resource = "*"
      }
    ]
  })
}

# policy attachment
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  for_each   = module.eks.self_managed_node_groups
  role       = each.value.iam_role_name
  policy_arn = aws_iam_policy.ssm_managed_instance.arn
}

