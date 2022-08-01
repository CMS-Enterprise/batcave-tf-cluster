locals {
  name            = var.cluster_name
  cluster_version = var.cluster_version
  region          = var.region
}

data "aws_ami" "eks_ami" {
  most_recent = true
  name_regex  = "^amzn2-eks-1.21"
  owners      = ["743302140042"]
}

################################################################################
# EKS Module
################################################################################
locals {
  custom_node_pools = { for k,v in var.custom_node_pools : k => {
      name                          = "${var.cluster_name}-${k}"
      subnet_ids                    = var.private_subnets
      ami_id                        = data.aws_ami.eks_ami.id
      iam_role_path                 = var.iam_role_path
      iam_role_permissions_boundary = var.iam_role_permissions_boundary

      instance_type                 = v.instance_type
      desired_size                  = v.desired_size
      max_size                      = v.max_size
      min_size                      = v.min_size
      bootstrap_extra_args          = try(v.extra_args, "--kubelet-extra-args '--node-labels=${k}=true --register-with-taints=${k}=true:NoSchedule'")
      create_security_group         = false
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
      tags = try(v.tags, null)
      propagate_tags = [
        {
          key                 = "ProjectName"
          value               = k
          propagate_at_launch = var.wg_tag_propagate_at_launch
        }
      ]
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.21.0"

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
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  enable_irsa                             = true

  ## VERY IMPORTANT WARNING: Changing security group ids associated with a cluster will
  ## ***DELETE AND RECREATE*** existing clusters.  Do not modify this for already existing clusters
  cluster_additional_security_group_ids = []

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  self_managed_node_group_defaults = {
    subnet_ids = var.private_subnets
  }
  # Worker groups (using Launch Configurations)
  self_managed_node_groups = merge({
    general = {
      name                          = "${var.cluster_name}-general"
      subnet_ids                    = var.private_subnets
      instance_type                 = var.instance_type
      iam_role_path                 = var.iam_role_path
      iam_role_permissions_boundary = var.iam_role_permissions_boundary
      bootstrap_extra_args          = var.general_nodepool_extra_args
      ami_id                        = data.aws_ami.eks_ami.id
      desired_size                  = var.desired_size
      max_size                      = var.max_size
      min_size                      = var.min_size
      target_group_arns = concat(
        [aws_lb_target_group.batcave_alb_https.arn],
        var.create_alb_proxy ? [aws_lb_target_group.batcave_alb_proxy_https[0].arn] : [],
      )
      create_security_group = false
      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = "300"
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      ]
      tags = var.general_nodepool_tags
      propagate_tags = [
        {
          key                 = "node_type"
          value               = "general"
          propagate_at_launch = var.wg_tag_propagate_at_launch
        }
      ]
    }
  }, local.custom_node_pools)
}

resource "null_resource" "instance_cleanup" {
  for_each = toset([var.cluster_name])
  depends_on = [
    module.eks
  ]
  triggers = {
    cluster_arn = module.eks.cluster_arn
  }
  provisioner "local-exec" {
    when = destroy
    # Clean up nodes created by karpenter for this cluster to ensure a clean delete
    command     = "aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filters \"Name=tag:kubernetes.io/cluster/${each.key},Values=owned\" \"Name=tag:karpenter.sh/provisioner-name,Values=*\" --query Reservations[].Instances[].InstanceId --output text) || true"
    interpreter = ["/bin/bash", "-c"]
  }
}

################################################################################
# Kubernetes provider configuration
################################################################################
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  configmap_roles = [ for k,v in module.eks.self_managed_node_groups : {
      rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${v.iam_role_name}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = tolist(concat(
        [
          "system:bootstrappers",
          "system:nodes",
        ],
      ))
    }
  ]
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = merge(
      {
        "app.kubernetes.io/managed-by" = "Terraform"
      }
    )
  }
  data = {
    mapRoles = yamlencode(
      distinct(concat(
        local.configmap_roles
      ))
    )

  }
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "batcave" {
  metadata {
    name = "batcave"
  }
  lifecycle {
    ignore_changes = [
      # Kustomize adds labels after the fact, ignore these changes
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

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


# egress for the worker nodes
resource "aws_security_group_rule" "allow_all_node_internet_egress" {
  for_each          = local.cluster_security_groups_created
  description       = "allow_all_node_internet_egress"
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = each.value
  cidr_blocks       = ["0.0.0.0/0"]
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
  description              = "Allow access form alb_proxy over port ${each.key}"
}

resource "aws_security_group_rule" "https-tg-ingress" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks       = ["10.0.0.0/8"]
}
