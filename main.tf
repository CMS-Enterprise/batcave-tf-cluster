locals {
  name                = var.cluster_name
  cluster_version     = var.cluster_version
  hoplimit_metadata   = var.enable_hoplimit ? { http_put_response_hop_limit = 1 } : {}
  is_bottlerocket_ami = contains(split("-", data.aws_ami.eks_ami.name), "bottlerocket")
}

data "aws_ami" "eks_ami" {
  most_recent = true
  name_regex  = var.use_bottlerocket ? "^bottlerocket-aws-k8s-${var.cluster_version}-x86_64-v1.17.0" : (var.ami_regex_override == "" ? "^amzn2-eks-${var.cluster_version}-gi-${var.ami_date}" : var.ami_regex_override)
  owners      = var.use_bottlerocket ? ["092701018921"] : (length(var.ami_owner_override) > 0 && var.ami_owner_override[0] != "" ? var.ami_owner_override : ["743302140042"])
}

data "aws_security_groups" "delete_ebs_volumes_lambda_security_group" {
  filter {
    name   = "group-name"
    values = ["delete_ebs_volumes-lambda"]
  }
}

################################################################################
# EKS Module
################################################################################
locals {
  # Schedule config
  create_schedule_startup     = var.node_schedule_startup_hour >= 0 || var.node_schedule_startup_cron != ""
  create_schedule_shutdown    = var.node_schedule_shutdown_hour >= 0 || var.node_schedule_shutdown_cron != ""
  create_schedule             = local.create_schedule_startup || local.create_schedule_shutdown
  node_schedule_shutdown_cron = var.node_schedule_shutdown_cron != "" ? var.node_schedule_shutdown_cron : "0 ${var.node_schedule_shutdown_hour} * * *"
  node_schedule_startup_cron  = var.node_schedule_startup_cron != "" ? var.node_schedule_startup_cron : "0 ${var.node_schedule_startup_hour} * * 1-5"

  instance_policy_tags = var.enable_ssm_patching ? { "Patch Group" = var.ssm_tag_patch_group, "Patch Window" = var.ssm_tag_patch_window } : {}
  instance_tags        = merge(local.instance_policy_tags, var.instance_tags)

  # Allow ingress to the control plane from the delete_ebs_volumes lambda (if it exists)
  delete_ebs_volumes_lambda_sg_id = one(data.aws_security_groups.delete_ebs_volumes_lambda_security_group.ids)
  default_security_group_additional_rules = (var.grant_delete_ebs_volumes_lambda_access && local.delete_ebs_volumes_lambda_sg_id != null ?
    ({
      delete_ebs_volumes_lambda_ingress_rule = {
        type                     = "ingress"
        protocol                 = "all"
        from_port                = 0
        to_port                  = 65535
        source_security_group_id = local.delete_ebs_volumes_lambda_sg_id
        description              = "Allow API connections from the delete_ebs_volumes lambda."
      }
    }) :
  {})
}

################################################################################
# EKS Fully managed nodes
################################################################################
locals {
  base_block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = "8"
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    },
    {
      device_name = "/dev/xvdb"
      ebs = {
        volume_size           = var.node_volume_size
        volume_type           = var.node_volume_type
        delete_on_termination = var.node_volume_delete_on_termination
        encrypted             = true
      }
    }
  ]

  eks_node_pools = { for k, v in merge({ general = var.general_node_pool }, var.custom_node_pools) : k => {
    group_name      = k
    name            = "${var.cluster_name}-${k}"
    cluster_name    = local.name
    cluster_version = local.cluster_version

    iam_role_path                 = var.iam_role_path
    iam_role_permissions_boundary = var.iam_role_permissions_boundary

    ami_id = data.aws_ami.eks_ami.id

    # Added for Bottlerocket
    use_custom_launch_template = try(v.use_custom_launch_template, true)
    ami_type                   = var.platform == "bottlerocket" ? "BOTTLEROCKET_x86_64" : "AL2_x86_64"
    platform                   = try(var.platform, "linux")
    bootstrap_extra_args       = <<-EOT
      # settings.kubernetes section from bootstrap_extra_args in default template
      pod-pids-limit = 1000

      # The admin host container provides SSH access and runs with "superpowers".
      # It is disabled by default, but can be disabled explicitly.
      [settings.host-containers.admin]
      enabled = false

      # The control host container provides out-of-band access via SSM.
      # It is enabled by default, and can be disabled if you do not expect to use SSM.
      # This could leave you with no way to access the API and change settings on an existing node!
      [settings.host-containers.control]
      enabled = true

      # extra args added
      [settings.kernel]
      lockdown = "integrity"
      user.max_user_namespaces = "10000"

      [settings.kubernetes.node-labels]
      # label1 = "foo"
      # label2 = "bar"

      [settings.kubernetes.node-taints]
      # dedicated = "experimental:PreferNoSchedule"
      # special = "true:NoSchedule"
    EOT

    subnet_ids = coalescelist(try(v.subnet_ids, []), var.host_subnets, var.private_subnets)

    min_size     = v.min_size
    max_size     = v.max_size
    desired_size = v.desired_size

    # This is dynamically creating the block device mappings based on the AMI type
    block_device_mappings = local.is_bottlerocket_ami ? local.base_block_device_mappings : [
      {
        device_name = "/dev/xvda"
        ebs = local.base_block_device_mappings[1].ebs
      }
    ]



    ## Define custom lines to the user_data script.  Separate commands with \n
    instance_type              = [v.instance_type]
    enable_bootstrap_user_data = true
    pre_bootstrap_user_data    = try(v.pre_bootstrap_user_data, "")
    post_bootstrap_user_data   = try(v.post_bootstrap_user_data, "")
    metadata_options           = merge(local.hoplimit_metadata, try(v.metadata_options, {}))

    tags = merge(var.tags, local.instance_tags, try(v.tags, null))

    taints = [
      for taint_key, taint_string in try(v.taints, {}) : {
        key    = taint_key
        value  = element(split(":", taint_string), 0)
        effect = "NO_SCHEDULE"
      }
    ]

    labels = {
      for label_key, label_value in try(v.labels, {}) :
      label_key => label_value
    }

    create_schedule = var.node_schedule_shutdown_hour >= 0 || var.node_schedule_startup_hour >= 0
    schedules = merge(
      var.node_schedule_shutdown_hour < 0 ? {} : {
        shutdown = {
          min_size     = 0
          max_size     = 0
          desired_size = 0
          time_zone    = var.node_schedule_timezone
          recurrence   = "0 ${var.node_schedule_shutdown_hour} * * *"
        }
      },
      var.node_schedule_startup_hour < 0 ? {} : {
        startup = {
          min_size     = v.min_size
          max_size     = v.max_size
          desired_size = v.desired_size
          time_zone    = var.node_schedule_timezone
          recurrence   = "0 ${var.node_schedule_startup_hour} * * 1-5"
        }
      }
    )
  } }
}

module "eks" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  iam_role_path                  = var.iam_role_path
  iam_role_permissions_boundary  = var.iam_role_permissions_boundary
  cluster_encryption_policy_path = var.iam_role_path
  # create_iam_role                = false
  # iam_role_arn                   = aws_iam_role.eks_node.arn

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_enabled_log_types               = var.cluster_enabled_log_types
  cluster_security_group_additional_rules = merge(local.default_security_group_additional_rules, var.cluster_security_group_additional_rules)
  enable_irsa                             = true

  # This is handled externally
  create_kms_key = false

  openid_connect_audiences = var.openid_connect_audiences

  ## VERY IMPORTANT WARNING: Changing security group ids associated with a cluster will
  ## ***DELETE AND RECREATE*** existing clusters.  Do not modify this for already existing clusters
  cluster_additional_security_group_ids = []

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  self_managed_node_group_defaults = {
    subnet_ids = coalescelist(var.host_subnets, var.private_subnets)
  }

  ## CLUSTER Addons
  cluster_addons = {}

  # apply any global tags to the cluster itself
  cluster_tags = var.tags
}

module "eks_managed_node_groups" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "19.21.0"

  for_each = local.eks_node_pools

  name                              = each.value.name
  cluster_name                      = each.value.cluster_name
  cluster_version                   = each.value.cluster_version
  cluster_endpoint                  = module.eks.cluster_endpoint
  cluster_auth_base64               = module.eks.cluster_certificate_authority_data
  create_iam_role                   = false
  iam_role_arn                      = aws_iam_role.eks_node.arn
  ami_id                            = each.value.ami_id
  subnet_ids                        = each.value.subnet_ids
  min_size                          = each.value.min_size
  max_size                          = each.value.max_size
  desired_size                      = each.value.desired_size
  block_device_mappings             = each.value.block_device_mappings
  instance_types                    = each.value.instance_type
  enable_bootstrap_user_data        = each.value.enable_bootstrap_user_data
  pre_bootstrap_user_data           = each.value.pre_bootstrap_user_data
  bootstrap_extra_args              = each.value.bootstrap_extra_args
  post_bootstrap_user_data          = each.value.post_bootstrap_user_data
  platform                          = each.value.platform
  ami_type                          = each.value.ami_type
  metadata_options                  = each.value.metadata_options
  tags                              = each.value.tags
  taints                            = each.value.taints
  labels                            = each.value.labels
  create_schedule                   = each.value.create_schedule
  schedules                         = each.value.schedules
  force_update_version              = var.force_update_version
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.33"

  role_name                     = "${var.cluster_name}-vpc_cni"
  attach_vpc_cni_policy         = true
  vpc_cni_enable_ipv4           = true
  role_path                     = var.iam_role_path
  role_permissions_boundary_arn = var.iam_role_permissions_boundary

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

# pseudo resource to capture critical infrastructure needed to access the Kubernetes API
resource "null_resource" "kubernetes_requirements" {
  depends_on = [
    module.eks,
    # without this security group rule the Kubernetes API is unreachable
    aws_security_group_rule.allow_ingress_additional_prefix_lists,
    aws_security_group_rule.allow_all_nodes_to_other_nodes,
    aws_security_group_rule.https-tg-ingress,
    aws_security_group_rule.https-vpc-ingress,
  ]
}

################################################################################
# Kubernetes provider configuration
################################################################################
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  cluster_security_groups_created = toset([
    { node = module.eks.node_security_group_id },
    { cluster = module.eks.cluster_security_group_id },
  ])

  cluster_security_groups_all = toset([
    { node = module.eks.node_security_group_id },
    { cluster = module.eks.cluster_security_group_id },
    { cluster_primary = module.eks.cluster_primary_security_group_id },
  ])

  # Hardcoding a list of x_allow_y to avoid terraform race conditions
  node_security_group_src_dst_keys = toset([for k in setproduct(["node", "cluster"], ["node", "cluster", "cluster_primary"]) : "${k[0]}_allow_${k[1]}"])

  cluster_security_groups_all_map = {
    node            = module.eks.node_security_group_id
    cluster         = module.eks.cluster_security_group_id
    cluster_primary = module.eks.cluster_primary_security_group_id
  }

  # List of all combinations of security_groups_created and security_groups_all
  node_security_group_setproduct = setproduct(
    local.cluster_security_groups_created,
    local.cluster_security_groups_all,
  )
  # Map of type: {"node_allow_cluster": {sg: "sg-1234", source_sg: "sg-2345"}, ...}
  node_security_group_src_dst = { for sg_pair in local.node_security_group_setproduct :
    "${keys(sg_pair[0])[0]}_allow_${keys(sg_pair[1])[0]}" =>
    { sg = one(values(sg_pair[0])), source_sg = one(values(sg_pair[1])) }
  }
}

# Ingress for provided prefix lists
resource "aws_security_group_rule" "allow_ingress_additional_prefix_lists" {
  for_each          = local.cluster_security_groups_all_map
  type              = "ingress"
  description       = "allow_ingress_additional_prefix_lists"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  prefix_list_ids   = var.cluster_additional_sg_prefix_lists
  security_group_id = each.value
}

## ingress between the cluster security groups
resource "aws_security_group_rule" "allow_all_nodes_to_other_nodes" {
  for_each                 = local.node_security_group_src_dst_keys
  description              = "allow all cluster nodes to other nodes"
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = local.node_security_group_src_dst[each.key].sg
  source_security_group_id = local.node_security_group_src_dst[each.key].source_sg
}

resource "aws_security_group_rule" "eks_node_ingress_alb_proxy" {
  for_each                 = var.create_alb_proxy ? toset(["80", "443"]) : toset([])
  type                     = "ingress"
  to_port                  = each.key
  from_port                = each.key
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = aws_security_group.batcave_alb_proxy[0].id
  description              = "Allow access from alb_proxy over port ${each.key}"
}

resource "aws_security_group_rule" "eks_node_ingress_alb_shared" {
  for_each                 = var.create_alb_shared ? toset(["80", "443"]) : toset([])
  type                     = "ingress"
  to_port                  = each.key
  from_port                = each.key
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = aws_security_group.batcave_alb_shared[0].id
  description              = "Allow access from shared ALB over port ${each.key}"
}

resource "aws_security_group_rule" "https-tg-ingress" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks       = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "https-vpc-ingress" {
  count             = 1
  type              = "ingress"
  to_port           = 443
  from_port         = 0
  protocol          = "tcp"
  security_group_id = module.eks.cluster_primary_security_group_id
  cidr_blocks       = var.vpc_cidr_blocks
}


## Setup for cosign keyless signatures
locals {
  oidc_provider = module.eks.oidc_provider
}

resource "aws_iam_role" "cosign" {
  count = var.create_cosign_iam_role ? 1 : 0

  name = "${var.cluster_name}-cosign"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
        }
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:aud" : "sigstore",
            "${local.oidc_provider}:sub" : "system:serviceaccount:gitlab-runner:cosign"
          }
        }
      },
    ]
  })
  path                 = var.iam_role_path
  permissions_boundary = var.iam_role_permissions_boundary
}

## Planning to move these out of the eks module, but need to wait until we're ready to deploy
#resource "aws_eks_addon" "vpc_cni" {
#  cluster_name = var.cluster_name
#  addon_name   = "vpc-cni"
#
#  addon_version     = var.addon_vpc_cni_version
#  resolve_conflicts = "OVERWRITE"
#
#  depends_on = [null_resource.kubernetes_requirements]
#}
#
#resource "aws_eks_addon" "kube_proxy" {
#  cluster_name = var.cluster_name
#  addon_name   = "kube-proxy"
#
#  addon_version     = var.addon_kube_proxy_version
#  resolve_conflicts = "OVERWRITE"
#
#  depends_on = [null_resource.kubernetes_requirements]
#}

resource "aws_autoscaling_attachment" "eks_managed_node_groups_alb_attachment" {
  for_each               = { for np in local.eks_node_pools : np.name => np }
  autoscaling_group_name = try(module.eks_managed_node_groups[each.value.group_name].node_group_autoscaling_group_names[0], "")

  lb_target_group_arn = aws_lb_target_group.batcave_alb_https.arn

  depends_on = [
    module.eks_managed_node_groups
  ]
}

resource "aws_autoscaling_attachment" "eks_managed_node_groups_proxy_attachment" {
  for_each               = var.create_alb_proxy ? { for np in local.eks_node_pools : np.name => np } : {}
  autoscaling_group_name = try(module.eks_managed_node_groups[each.value.group_name].node_group_autoscaling_group_names[0], "")

  lb_target_group_arn = var.create_alb_proxy ? aws_lb_target_group.batcave_alb_proxy_https[0].arn : null

  depends_on = [
    module.eks_managed_node_groups
  ]
}

resource "aws_autoscaling_attachment" "eks_managed_node_groups_shared_attachment" {
  for_each               = var.create_alb_shared ? { for np in local.eks_node_pools : np.name => np } : {}
  autoscaling_group_name = try(module.eks_managed_node_groups[each.value.group_name].node_group_autoscaling_group_names[0], "")

  lb_target_group_arn = var.create_alb_shared ? aws_lb_target_group.batcave_alb_shared_https[0].arn : null

  depends_on = [
    module.eks_managed_node_groups
  ]
}
