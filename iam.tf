# IAM policy to access KMS key
# Get Arn for SOPS KMS policy
data "aws_kms_alias" "sops" {
  name = "alias/batcave-landing-sops"
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid     = "kmsuse"
    actions = [
      "kms:*",
    ]
    resources = [
      data.aws_kms_alias.sops.arn,
      data.aws_kms_alias.sops.target_key_arn,
    ]
  }
  statement {
    sid     = "kmslist"
    actions = [
      "kms:List*",
      "kms:Describe*",
    ]
    resources = ["*"]
  }
}

# KMS policy to allow sops key only
resource "aws_iam_policy" "kms_policy" {
  name        = "${local.name}-kms_policy"
  path        = var.iam_role_path
  description = "IAM policy to access KMS key"
  policy      = data.aws_iam_policy_document.kms_policy.json
}

# Attach KMS policy to node IAM role
resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = module.eks.self_managed_node_groups
  policy_arn = aws_iam_policy.kms_policy.arn
  role       = each.value.iam_role_name
}

# Secrets Manager policy
resource "aws_iam_policy" "secretsmanager_policy" {
  name        = "${local.name}-secretsmanager-policy"
  path        = var.iam_role_path
  description = "IAM policy to access secretsm manager"
  policy      = jsonencode({
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

### S3 access policy for nodes
resource "aws_iam_policy" "s3_policy" {
  name        = "${local.name}-s3_policy"
  path        = var.iam_role_path
  description = "S3 access policy for nodes"
  policy      = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "s3fullaccess",
        "Action" : "s3:*",
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}

# Attach S3 policy to node IAM role
resource "aws_iam_role_policy_attachment" "additional_policy_s3" {
  for_each   = module.eks.self_managed_node_groups
  policy_arn = aws_iam_policy.s3_policy.arn
  role       = each.value.iam_role_name
}

### S3 access policy for nodes
resource "aws_iam_policy" "velero_policy" {
  name        = "${local.name}-velero_policy"
  path        = var.iam_role_path
  description = "Velero backup policy for nodes"
  policy      = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "veleroaccess",
        "Action": [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}

# Attach S3 policy to node IAM role
resource "aws_iam_role_policy_attachment" "additional_policy_velero" {
  for_each   = module.eks.self_managed_node_groups
  policy_arn = aws_iam_policy.velero_policy.arn
  role       = each.value.iam_role_name
}


# Cloudwatch Logs policy
data "aws_iam_policy_document" "cloudwatch_logs_policy" {
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

resource "aws_iam_policy" "cloudwatchlogs_policy" {
  name        = "${local.name}-cloudwatchlogs-policy"
  path        = var.iam_role_path
  description = "IAM policy to access cloudwatch logs"
  policy      = data.aws_iam_policy_document.cloudwatch_logs_policy.json
}

# Attach cloudwatchlogs policy to node IAM role
resource "aws_iam_role_policy_attachment" "cloudwatchlogs" {
  for_each   = module.eks.self_managed_node_groups
  policy_arn = aws_iam_policy.cloudwatchlogs_policy.arn
  role       = each.value.iam_role_name
}