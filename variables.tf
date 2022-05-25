variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "cluster_version" {
  default = "1.21"
}

### Default node group vars

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

### Runners node group vars

variable "runners_desired_size" {
  type    = number
  default = 1
}

variable "runners_max_size" {
  type    = number
  default = 1
}

variable "runners_min_size" {
  type    = number
  default = 1
}

variable "runners_instance_type" {
  default = "c4.xlarge"
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
  type    = map(string)
  default = {}
}

variable "transport_subnets_by_zone" {
  type    = map(string)
  default = {}
}

variable "transport_subnets" {
  type    = list(any)
  default = []
}

variable "nlb_subnets_by_zone" {
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

variable "transport_proxy_static_ip" {
  type    = bool
  default = true
}

variable "transport_proxy_is_internal" {
  type        = bool
  default     = true
  description = "Boolean to trigger a public transport proxy ip"
}

variable "cluster_additional_sg_prefix_lists" {
  type = list(string)
}

variable "cluster_security_group_additional_rules" {
  type        = map(any)
  description = "Map of security group rules to attach to the cluster security group, as you cannot change cluster security groups without replacing the instance"
  default     = {}
}

variable "nlb_deletion_protection" {
  type    = bool
  default = false
}

variable "create_transport_proxy_lb" {
  type        = bool
  default     = false
  description = "Optionally create a network load balancer in the transport subnet.  Requires VPC to be configured to fetch transport subnet data"
}

variable "node_https_ingress_cidr_blocks" {
  description = "List of CIDR blocks to allow into the node over the HTTPs port"
  default     = ["10.0.0.0/8"]
  type        = list(string)
}

variable "create_alb_proxy" {
  type        = bool
  description = "Create an Application Load Balancer proxy to live in front of the NLB and act as a proxy from the public Internet"
  default     = false
}
variable "alb_proxy_is_internal" {
  type        = bool
  description = "If the ALB Proxy should be using internal ips.  Defaults to false, because the reason for ALB proxy existing is typically to make it accessible over the Internet"
  default     = false
}

variable "alb_proxy_subnets" {
  description = "List of subnet ids for the ALB Proxy to be deployed into"
  default     = []
  type        = list(string)
}

variable "acm_cert_base_domain" {
  description = "Base domain of the certificate used for the ALB Proxy"
  default     = ""
  type        = string
}

variable "alb_proxy_ingress_cidrs" {
  description = "List of CIDR blocks allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs"
  default     = []
  type        = list(string)
}
variable "alb_proxy_ingress_prefix_lists" {
  description = "List of Prefix List IDs allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs"
  default     = []
  type        = list(string)
}
