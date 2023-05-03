# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/UPGRADE-19.0.md#added

terragrunt state mv 'module.eks.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]' 'module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]'
terragrunt state mv 'module.eks.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"]' 'module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]'
