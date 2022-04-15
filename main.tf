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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.20.1"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  iam_role_path                 = var.iam_role_path
  iam_role_permissions_boundary = var.iam_role_permissions_boundary
  cluster_encryption_policy_path = var.iam_role_path


  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  cluster_endpoint_private_access         = var.cluster_endpoint_private_access
  cluster_endpoint_public_access          = var.cluster_endpoint_public_access
  cluster_enabled_log_types               = var.cluster_enabled_log_types
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  enable_irsa                             = var.enable_irsa

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
  self_managed_node_groups = {
    general = {
      name                          = "${var.cluster_name}-general"
      subnet_ids                    = var.private_subnets
      instance_type                 = var.instance_type
      iam_role_path                 = var.iam_role_path
      iam_role_permissions_boundary = var.iam_role_permissions_boundary
      bootstrap_extra_args          = "--kubelet-extra-args '--node-labels=general=true'"
      ami_id                        = data.aws_ami.eks_ami.id
      desired_size                  = var.desired_size
      max_size                      = var.max_size
      min_size                      = var.min_size
      target_group_arn              = [aws_lb_target_group.batcave-tg-https.arn, aws_lb_target_group.batcave-tg-http.arn]
      create_security_group         = false
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

      propagate_tags = [
        {
          key                 = "Node_type"
          value               = "General"
          propagate_at_launch = var.wg_tag_propagate_at_launch
        }
      ]
    }
    gitlab-runners = {
      name                          = "${var.cluster_name}-runners"
      subnet_ids                    = var.private_subnets
      instance_type                 = var.runners_instance_type
      iam_role_path                 = var.iam_role_path
      iam_role_permissions_boundary = var.iam_role_permissions_boundary
      bootstrap_extra_args          = "--kubelet-extra-args '--node-labels=runners=true --register-with-taints=runners=true:NoSchedule'"
      ami_id                        = data.aws_ami.eks_ami.id
      desired_size                  = var.runners_desired_size
      max_size                      = var.runners_max_size
      min_size                      = var.runners_min_size
      create_security_group         = false
      target_group_arn              = [aws_lb_target_group.batcave-tg-https.arn,aws_lb_target_group.batcave-tg-http.arn]
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

      propagate_tags = [
        {
          key                 = "Node_type"
          value               = "runners"
          propagate_at_launch = var.wg_tag_propagate_at_launch
        }
      ]
    }
  }
  tags = {
    Environment = var.environment
  }
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
  host                   = data.aws_eks_cluster.cluster.endpoint
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
  configmap_roles = [
    {
      rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${module.eks.self_managed_node_groups.general.iam_role_name}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = tolist(concat(
        [
          "system:bootstrappers",
          "system:nodes",
        ],
      ))
    },
    {
      rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${module.eks.self_managed_node_groups.gitlab-runners.iam_role_name}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = tolist(concat(
        [
          "system:bootstrappers",
          "system:nodes",
        ],
      ))
    }
    # {
    #   rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${module.eks.self_managed_node_groups.memory.iam_role_name}"
    #   username = "system:node:{{EC2PrivateDNSName}}"
    #   groups = tolist(concat(
    #     [
    #       "system:bootstrappers",
    #       "system:nodes",
    #     ],
    #   ))
    # }
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

### Security group rules for cluster_primary_securiy_group_id
resource "aws_security_group_rule" "allow_all_cluster_primary_2" {
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
}

resource "aws_security_group_rule" "allow_all_cluster_primary_3" {
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = module.eks.node_security_group_id
}

# Security group rules for cluster_security_group_id
resource "aws_security_group_rule" "allow_all_cluster_1" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.cluster_security_group_id
  self              = true
}
resource "aws_security_group_rule" "allow_all_cluster_2" {
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.eks.node_security_group_id
}
resource "aws_security_group_rule" "allow_all_cluster_3" {
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

# Security group rules for cluster_security_group_id
resource "aws_security_group_rule" "allow_all_worker_1" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  self              = true
}
resource "aws_security_group_rule" "allow_all_worker_2" {
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
}
resource "aws_security_group_rule" "allow_all_worker_3" {
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

### Security group rules for cluster_primary_securiy_group_id

resource "aws_security_group_rule" "allow_all_cluster_primary_2_egress" {
  type                     = "egress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
}

resource "aws_security_group_rule" "allow_all_cluster_primary_3_egress" {
  type                     = "egress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = module.eks.node_security_group_id
}

resource "aws_security_group_rule" "allow_ingress_additional_prefix_lists" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  prefix_list_ids   = var.cluster_additional_sg_prefix_lists
  security_group_id = module.eks.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "allow_ingress_additional_prefix_lists_worker" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  prefix_list_ids   = var.cluster_additional_sg_prefix_lists
  security_group_id = module.eks.node_security_group_id
}

resource "aws_security_group_rule" "allow_ingress_additional_prefix_lists_secondary" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  prefix_list_ids   = var.cluster_additional_sg_prefix_lists
  security_group_id = module.eks.cluster_security_group_id
}

# ### Security group rules for cluster_security_group_id
resource "aws_security_group_rule" "allow_all_cluster_1_egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.cluster_security_group_id
  self              = true
}
resource "aws_security_group_rule" "allow_all_cluster_2_egress" {
  type                     = "egress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.eks.node_security_group_id
}
resource "aws_security_group_rule" "allow_all_cluster_3_egress" {
  type                     = "egress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

### Security group rules for cluster_security_group_id

resource "aws_security_group_rule" "allow_all_worker_1_egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  self              = true
}
resource "aws_security_group_rule" "allow_all_worker_2_egress" {
  type                     = "egress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
}
resource "aws_security_group_rule" "allow_all_worker_3_egress" {
  type                     = "egress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

# egress for the worker nodes
# resource "aws_security_group_rule" "allow_all_worker_egress" {
#   description              = "outbound bastion traffic"
#   type                     = "egress"
#   to_port                  = 0
#   from_port                = 0
#   protocol                 = "-1"
#   security_group_id        = module.eks.node_security_group_id
#   source_security_group_id = module.eks.cluster_security_group_id
# }

# egress for the worker nodes
resource "aws_security_group_rule" "allow_all_worker_internet_egress" {
  description       = "outbound nodes traffic"
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https-tg-ingress" {
  type                     = "ingress"
  to_port                  = 0
  from_port                = 0
  protocol                 = "-1"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks              = ["10.0.0.0/8"]
}