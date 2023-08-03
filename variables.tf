variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "cluster_version" {
  default = "1.25"
}

variable "ami_date" {
  default = ""
}

## Default node group
variable "general_node_pool" {
  type        = any
  description = "General node pool, required for hosting core services"
  default = {
    instance_type = "c5.2xlarge"
    desired_size  = 3
    max_size      = 5
    min_size      = 2
    # Map of label flags for kubelets.
    labels = { general = "true" }
    # Map of taint flags for kubelets.
    # Ex: `{MyTaint = "true:NoSchedule"}`
    taints = {}
    #tags = {}

    # Extra args for kubelet in form of: "--node-labels=general=true <...>'.  Will be in _addition_ to any
    # other args added by the labels and taints values
    #extra_args = "--node-labels=general=true"

    #volume_size                  = "300"
    #volume_type                  = "gp3"
    #volume_delete_on_termination = true

    #subnet_ids = [ "list","of","subnet","ids" ]
  }
}

variable "custom_node_pools" {
  type    = any
  default = {}
  #  runners = {
  #    instance_type = "c4.xlarge"
  #    desired_size = 1
  #    max_size = 1
  #    min_size = 1
  #    labels = { gitlab-runners-go-here = "true" }
  #    taints = { better-watch-out-for-gitlab-runners = "true:NoSchedule" }
  #    subnet_ids = [ "list","of","subnet","ids" ]
  #  }
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

variable "host_subnets" {
  type        = list(any)
  default     = []
  description = "Override the ec2 instance subnets.  By default, they are launche in private_subnets, just like the EKS control plane."
}

variable "alb_subnets_by_zone" {
  type = map(string)
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_irsa" {
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

variable "tags" {
  default     = null
  description = "Global resource tags to apply to all resources"
  type        = map(any)
}
variable "instance_tags" {
  default     = null
  description = "Instance custom tags"
  type        = map(any)
}
variable "volume_tag" {
  default     = null
  description = "Volume custom tag"
  type        = map(any)
}
variable "network_interface_tag" {
  default     = null
  description = "Network Interface custom tag"
  type        = map(any)
}

variable "general_nodepool_tags" {
  default     = null
  description = "General Node Pool tags"
  type        = map(any)
}
### Launch template tags

variable "lt_CustomTag" {
  default     = null
  description = "Launch template custom tag"
  type        = map(any)
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

variable "grant_delete_ebs_volumes_lambda_access" {
  type        = bool
  default     = false
  description = "When set to true, a cluster role and permissions will be created to grant the delete-ebs-volumes Lambda access to the PersistentVolumes API."
}

variable "node_https_ingress_cidr_blocks" {
  description = "List of CIDR blocks to allow into the node over the HTTPs port"
  default     = ["10.0.0.0/8", "100.0.0.0/8"]
  type        = list(string)
}

variable "create_alb_proxy" {
  type        = bool
  description = "Create an Application Load Balancer proxy to live in front of the K8s ALB and act as a proxy from the public Internet"
  default     = false
}
variable "alb_proxy_is_internal" {
  type        = bool
  description = "If the ALB Proxy should be using internal ips. Defaults to false, because the reason for ALB proxy existing is typically to make it accessible over the Internet"
  default     = false
}

variable "alb_proxy_subnets" {
  description = "List of subnet ids for the ALB Proxy to be deployed into"
  default     = []
  type        = list(string)
}

variable "create_alb_shared" {
  type        = bool
  description = "Creaes an ALB in the shared subnet"
  default     = false
}

variable "alb_shared_is_internal" {
  type        = bool
  description = "If the ALB in the shared subnet should be using internal ips. Defaults to false, because the reason for this ALB existing is to make it accessible over the Internet"
  default     = false
}

variable "alb_shared_subnets" {
  description = "List of subnet ids for the ALB in the shared subnet"
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

variable "alb_shared_ingress_cidrs" {
  description = "List of CIDR blocks allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs"
  default     = []
  type        = list(string)
}
variable "alb_shared_ingress_prefix_lists" {
  description = "List of Prefix List IDs allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs"
  default     = []
  type        = list(string)
}

variable "alb_deletion_protection" {
  description = "Enable/Disable ALB deletion protection for both ALBs"
  default     = false
  type        = bool
}
variable "alb_drop_invalid_header_fields" {
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false). The default is false. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type application"
  default     = true
  type        = bool
}

variable "alb_idle_timeout" {
  description = "Default idle request timeout for the ALB"
  default     = "60"
  type        = string
}

variable "alb_public_tags" {
  description = "Additional public ALB tags"
  default     = null
  type        = map(any)
}

variable "alb_private_tags" {
  description = "Additional private ALB tags"
  default     = null
  type        = map(any)
}

variable "s3_bucket_access_grants" {
  description = "A list of s3 bucket names to grant the cluster roles R/W access to"
  default     = null
  type        = list(string)
}

variable "logging_bucket" {
  description = "Name of the S3 bucket to send load balancer access logs."
  default     = null
  type        = string
}

### Cosign OpenID Connect Audiences
variable "openid_connect_audiences" {
  description = "OpenID Connect Audiences"
  default     = []
  type        = list(string)
}
variable "create_cosign_iam_role" {
  description = "Flag to create Cosign IAM role"
  default     = false
}

variable "autoscaling_group_tags" {
  description = "Tags to apply to all autoscaling groups created"
  default     = {}
  type        = map(any)
}

variable "ami_regex_override" {
  description = "Overrides default AMI lookup regex, which grabs latest AMI matching cluster_version by default"
  default     = ""
  type        = string
}
variable "addon_vpc_cni_version" {
  description = "This is the image of the CNI pod used in the vpc-cni addon.  For other options, run: aws eks describe-addon-versions --add"
  default     = "v1.12.6-eksbuild.1"
  type        = string
}
variable "addon_kube_proxy_version" {
  description = " This is the image of the kube_proxy used as addon"
  default     = "v1.24.10-eksbuild.2 "
  type        = string
}
variable "aolytix_role_access" {
  type        = bool
  default     = true
  description = "When set to false, this is not allow kubernetes data to be pulled by the aolytix application"
}
variable "github_actions_role_access" {
  type        = bool
  default     = true
  description = "When set to false, this is not allow kubernetes data to be pulled by the github actions"
}
variable "node_schedule_shutdown_hour" {
  type        = number
  default     = -1
  description = "The hour of the day (0-23) the cluster should be shutdown.  If left empty, the cluster will not be stopped. Will run every day otherwise."
}
variable "node_schedule_startup_hour" {
  type        = number
  default     = -1
  description = "The hour of the day (0-23) the cluster should be restarted.  If left empty, the cluster will not be restarted after shutdown. Will run every weekday otherwise."
}
variable "node_schedule_timezone" {
  type        = string
  default     = "America/New_York"
  description = "The timezone of the schedule. Ex: 'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles', 'Pacific/Honolulu'  See: https://www.joda.org/joda-time/timezones.html"
}

variable "enable_hoplimit" {
  type        = bool
  default     = false
  description = "Enables a IMDSv2 hop limit of 1 on all nodes. Defaults to false"
}

variable "configmap_custom_roles" {
  default     = []
  description = "A custom list of IAM role names to include in the aws-auth configmap"
  type        = list(string)
}

variable "vpc_cidr_blocks" {
  default = []
  description = "List of VPC CIDR blocks"
  type        = list(string)
}

variable "github_actions_role" {
  type        = string
  default     = "batcave-github-actions-role"
  description = "Github actions role"
}

### Federated role will be added to the ConfigMap so that the users can have access to the Kubernetes objects of the cluster.
### By default the users will not have access when the cluster is created by GitHub runner.
variable "federated_access_role" {
  type        = string
  default     = "ct-ado-batcave-application-admin"
  description = "Federated access role"
}
