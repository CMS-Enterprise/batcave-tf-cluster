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