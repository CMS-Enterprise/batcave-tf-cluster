locals {
  name              = var.cluster_name
  cluster_version   = var.cluster_version
  region            = var.region
  alb_idle_timeout  = var.alb_idle_timeout
  hoplimit_metadata = var.enable_hoplimit ? { http_put_response_hop_limit = 1 } : {}
}

data "aws_ami" "eks_ami" {
  most_recent = true
  name_regex  = var.ami_regex_override == "" ? "^amzn2-eks-${var.cluster_version}-gi-${var.ami_date}" : var.ami_regex_override
  owners      = ["743302140042"]
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
  custom_node_pools = { for k, v in merge({ general = var.general_node_pool }, var.custom_node_pools) : k => {
    name                          = "${var.cluster_name}-${k}"
    subnet_ids                    = coalescelist(try(v.subnet_ids, []), var.host_subnets, var.private_subnets)
    ami_id                        = data.aws_ami.eks_ami.id
    iam_role_path                 = var.iam_role_path
    iam_role_permissions_boundary = var.iam_role_permissions_boundary

    instance_type           = v.instance_type
    desired_size            = v.desired_size
    max_size                = v.max_size
    min_size                = v.min_size
    pre_bootstrap_user_data = "sysctl -w net.ipv4.ip_forward=1\n"
    bootstrap_extra_args = join(" ",
      ["--kubelet-extra-args '--node-labels=${k}=true", try(v.extra_args, "")],
      [for label_key, label_value in try(v.labels, {}) : "--node-labels=${label_key}=${label_value}"],
      [for taint_key, taint_value in try(v.taints, {}) : "--register-with-taints=${taint_key}=${taint_value}"],
      ["'"]
    )
    create_security_group = false
    block_device_mappings = [
      {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = try(v.volume_size, "300")
          volume_type           = try(v.volume_type, "gp3")
          delete_on_termination = try(v.volume_delete_on_termination, true)
          encrypted             = true
        }
      }
    ]

    # On the general node group or any node group labeled "general", attach target groups
    target_group_arns = (k == "general" || contains(keys(try(v.labels, {})), "general")) ? concat(
      [aws_lb_target_group.batcave_alb_https.arn],
      var.create_alb_proxy ? [aws_lb_target_group.batcave_alb_proxy_https[0].arn] : [],
      var.create_alb_shared ? [aws_lb_target_group.batcave_alb_shared_https[0].arn] : []
    ) : null

    tags = merge(var.tags, var.instance_tags, try(v.tags, null))

    metadata_options = merge(local.hoplimit_metadata, try(v.metadata_options, {}))

    ## Tags that are applied _ONLY_ to the ASG resource and not propagated to the nodes
    ## All the "tags" var will be applied to both ASG and Propagated out to the nodes
    autoscaling_group_tags = merge(
      {
        "k8s.io/cluster-autoscaler/enabled"             = "true",
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "${var.cluster_name}"
      },
      # Taint tags for Cluster Autoscaler hints
      try({ for taint_key, taint_value in v.taints : "k8s.io/cluster-autoscaler/node-template/taint/${taint_key}" => taint_value }, {}),
      # Label tags for Cluster Autoscaler hints
      { "k8s.io/cluster-autoscaler/node-template/label/${k}" = "true" },
      try({ for label_key, label_value in v.labels : "k8s.io/cluster-autoscaler/node-template/label/${label_key}" => label_value }, {}),
      var.autoscaling_group_tags,
    )
    enabled_metrics = [
      "GroupAndWarmPoolDesiredCapacity",
      "GroupAndWarmPoolTotalCapacity",
      "GroupDesiredCapacity",
      "GroupInServiceCapacity",
      "GroupInServiceInstances",
      "GroupMaxSize",
      "GroupMinSize",
      "GroupPendingCapacity",
      "GroupPendingInstances",
      "GroupStandbyCapacity",
      "GroupStandbyInstances",
      "GroupTerminatingCapacity",
      "GroupTerminatingInstances",
      "GroupTotalCapacity",
      "GroupTotalInstances",
      "WarmPoolDesiredCapacity",
      "WarmPoolMinSize",
      "WarmPoolPendingCapacity",
      "WarmPoolTerminatingCapacity",
      "WarmPoolTotalCapacity",
      "WarmPoolWarmedCapacity",
    ]
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

    ## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#instance_refresh
    instance_refresh = lookup(v, "instance_refresh", {})
  } }
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

module "eks" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  iam_role_path                  = var.iam_role_path
  iam_role_permissions_boundary  = var.iam_role_permissions_boundary
  cluster_encryption_policy_path = var.iam_role_path


  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  cluster_endpoint_private_access         = var.cluster_endpoint_private_access
  cluster_endpoint_public_access          = var.cluster_endpoint_public_access
  cluster_enabled_log_types               = var.cluster_enabled_log_types
  cluster_security_group_additional_rules = merge(local.default_security_group_additional_rules, var.cluster_security_group_additional_rules, var.node_https_ingress_cidr_blocks)
  enable_irsa                             = true

  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  #create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  # aws-auth configmap
  #manage_aws_auth_configmap = true

  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/ct-ado-batcave-developer-admin",
  #     username = "ct-ado-batcave-developer-admin",
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/batcave-github-actions-role",
  #     username = "batcave-github-actions-role",
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/aolytix-role",
  #     username = "aolytix-role",
  #     groups   = ["system:masters"]
  #   }
  # ]
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
  cluster_addons = {
    #vpc-cni = {
    #  resolve_conflicts        = "OVERWRITE"
    #  service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    #  addon_version            = var.addon_vpc_cni_version
    #}
    #kube-proxy = {
    #  resolve_conflicts = "OVERWRITE"
    #  addon_version     = var.addon_kube_proxy_version
    #}
  }
  # Worker groups (using Launch Configurations)
  self_managed_node_groups = local.custom_node_pools

  # apply any global tags to the cluster itself
  cluster_tags = var.tags
}
module "vpc_cni_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

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
  cluster_security_groups_created = {
    "node" : module.eks.node_security_group_id,
    "cluster" : module.eks.cluster_security_group_id,
  }

  cluster_security_groups_all = {
    "node" : module.eks.node_security_group_id,
    "cluster" : module.eks.cluster_security_group_id,
    "cluster_primary" : module.eks.cluster_primary_security_group_id,
  }

  # List of all combinations of security_groups_created and security_groups_all
  node_security_group_setproduct = setproduct(
    [for k, v in local.cluster_security_groups_created : { "${k}" : v }],
    [for k, v in local.cluster_security_groups_all : { "${k}" : v }],
  )
  # Map of type: {"node_allow_cluster": {sg: "sg-1234", source_sg: "sg-2345"}, ...}
  node_security_group_src_dst = { for sg_pair in local.node_security_group_setproduct :
    "${keys(sg_pair[0])[0]}_allow_${keys(sg_pair[1])[0]}" =>
    { sg = one(values(sg_pair[0])), source_sg = one(values(sg_pair[1])) }
  }
}

# Ingress for provided prefix lists
resource "aws_security_group_rule" "allow_ingress_additional_prefix_lists" {
  for_each          = local.cluster_security_groups_all
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
  for_each                 = local.node_security_group_src_dst
  description              = "allow all cluster nodes to other nodes"
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = each.value.sg
  source_security_group_id = each.value.source_sg
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
