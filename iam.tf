# IAM policy to access KMS key
# Get Arn for SOPS KMS policy
data "aws_kms_alias" "sops" {
  name = "alias/batcave-landing-sops"
}

data "aws_iam_policy_document" "node_policy" {
  statement {
    sid = "K8sNodes"
    actions = [
      "kms:Decrypt",
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
    ]
    resources = ["*"]
  }
  statement {
    sid = "ec2snapshot"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "stsassumerole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    # self-referential ARN used by Rapidfort to allow the pod to assume a role
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/delegatedadmin/developer/*general-node-group*"
    ]

  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = (var.s3_bucket_access_grants == null ?
      # Use legacy default
      [
        "arn:aws:s3:::${var.cluster_name}*velero-storage",
        "arn:aws:s3:::batcave*runner-cache",
        "arn:aws:s3:::batcave*gitlab*",
        "arn:aws:s3:::rapidfort*storage"
      ] :
      [
        for bucket in var.s3_bucket_access_grants : "arn:aws:s3:::${bucket}"
    ])
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:List*"
    ]
    resources = (var.s3_bucket_access_grants == null ?
      # Use legacy default
      [
        "arn:aws:s3:::${var.cluster_name}*velero-storage/*",
        "arn:aws:s3:::batcave*runner-cache/*",
        "arn:aws:s3:::batcave*gitlab*/*",
        "arn:aws:s3:::rapidfort*storage/*"
      ] :
      [
        for bucket in var.s3_bucket_access_grants : "arn:aws:s3:::${bucket}/*"
    ])
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
  # for_each   = module.eks_managed_node_group
  policy_arn = aws_iam_policy.node_policy.arn
  # role       = each.value.iam_role_name
  role = aws_iam_role.eks_node.name
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
  # for_each   = module.eks_managed_node_group
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
  # role       = each.value.iam_role_name
  role = aws_iam_role.eks_node.name
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

# Policy attachment for the ebs csi driver. Policy provided from AWS for ebs csi driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  for_each   = module.eks.self_managed_node_groups
  role       = each.value.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# create node IAM role
# Need to create because decided to create EKS cluster then deploy EKS fully managed nodes.check "

resource "aws_iam_role" "eks_node" {
  name                 = "eks-node-${var.cluster_name}-role"
  path                 = var.iam_role_path
  permissions_boundary = var.iam_role_permissions_boundary # Using the variable here


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSNodeAssumeRole"
        Effect = "Allow"
        Principal = {
          "Service" : [
            "eks.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ])

  policy_arn = each.key
  role       = aws_iam_role.eks_node.name
}
