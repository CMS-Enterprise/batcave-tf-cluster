variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "cluster_version" {
  default = "1.21"
}

variable "runners_desired_size" {
  default = 0
}
variable "runners_max_size" {
  default = 0
}
variable "runners_min_size" {
  default = 0
}
variable "desired_size" {
  default = 3
}
variable "max_size" {
  default = 3
}
variable "min_size" {
  default = 3
}
variable "instance_type" {
  default = "c5.2xlarge"
}

variable "cluster_name" {}

variable "iam_role_path" {
  default = "/delegatedadmin/developer/"
}

variable "iam_role_permissions_boundary" {
  default = "arn:aws:iam::373346310182:policy/cms-cloud-admin/developer-boundary-policy"
}

variable "vpc_id" {}

variable "private_subnets" {
  type = list(any)
}

variable "transport_subnet_cidr_blocks" {
  type = map(string)
}

variable "cluster_endpoint_private_access" {
  default = "true"
}
variable "cluster_endpoint_public_access" {
  default = "true"
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_irsa" {
  default = "true"
}


### Worker Group variables

variable "wg_instance_type" {
  default = "t3.xlarge"
}
variable "wg_kubelet_extra_args" {
  default = "--node-labels=bootstrap --register-with-taints=CriticalAddonsOnly=true:NoSchedule"
}
variable "wg_ami_id" {
  default = "ami-0d111bb0f1e4a9787"
}
variable "wg_general_asg_desired_size" {
  type    = number
  default = 1
}
variable "wg_general_asg_max_size" {
  type    = number
  default = 5
}
variable "wg_general_asg_min_size" {
  type    = number
  default = 1
}
variable "wg_instance_refresh_enabled" {
  type    = bool
  default = true
}
variable "wg_instance_refresh_strategy" {
  default = "Rolling"
}
variable "wg_instance_refresh_instance_warmup" {
  type    = number
  default = 90
}
variable "wg_tag_key" {
  default = "restart_filter"
}
variable "wg_tag_value" {
  default = "bootstrap"
}
variable "wg_tag_propagate_at_launch" {
  default = "true"
}


### AWS Launch Template variables

variable "lt_name_prefix" {
  default = "eks-lt-"
}
variable "lt_description" {
  default = "Default Launch-Template"
}
variable "lt_update_default_version" {
  default = "true"
}
variable "lt_image_id" {
  default = "ami-0d111bb0f1e4a9787"
}


### Block device mappings

variable "block_device_name" {
  default = "/dev/xvda"
}
variable "block_volume_size" {
  type    = number
  default = 100
}
variable "block_volume_type" {
  default = "gp2"
}
variable "block_delete_on_termination" {
  default = "true"
}
variable "block_encrypted" {
  default = "true"
}


### Monitoring
variable "lt_monitoring_enabled" {
  default = "true"
}


### Network Interfaces
variable "network_int_associate_public_ip_address" {
  default = "false"
}
variable "network_int_delete_on_termination" {
  default = "true"
}


### Resource tags

variable "instance_tag" {
  default = "Instance custom tag"
}
variable "volume_tag" {
  default = "Volume custom tag"
}
variable "network_interface_tag" {
  default = "Network Interface custom tag"
}


### Launch template tags

variable "lt_CustomTag" {
  default = "Launch template custom tag"
}


# ## KMS Key ARN from KMS module
# variable "kms_key_arn" {}

variable "create_transport_nlb" {
  type        = bool
  default     = false
  description = "Optionally create a network load balancer in the transport subnet.  Requires VPC to be configured to fetch transport subnet data"
}

variable "cluster_additional_security_group_ids" {
  type = list(string)
}

variable "cluster_additional_sg_prefix_lists" {
  type = list(string)
}

variable "cluster_security_group_additional_rules" {
  type        = map(any)
  description = "Map of security group rules to attach to the cluster security group, as you cannot change cluster security groups without replacing the instance"
  default     = {}
}
