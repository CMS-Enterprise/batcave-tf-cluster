# Launch template with managed groups example

This is EKS example using workers custom launch template with managed groups feature in two different ways:

- Using a defined existing launch template created outside module
- Using dlaunch template which will be created by module with user customization

See [the official documentation](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) for more details.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.4 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.0.4 |
| <a name="module_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#module\_eks\_managed\_node\_groups) | terraform-aws-modules/eks/aws//modules/eks-managed-node-group | 19.21.0 |
| <a name="module_vpc_cni_irsa"></a> [vpc\_cni\_irsa](#module\_vpc\_cni\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.33 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_attachment.eks_managed_node_groups_alb_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_autoscaling_attachment.eks_managed_node_groups_proxy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_autoscaling_attachment.eks_managed_node_groups_shared_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_iam_policy.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cosign](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cloudwatch_plolicy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_custom_node_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_node_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_patching_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_service_linked_role.autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_kms_key.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lb.batcave_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.batcave_alb_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.batcave_alb_shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.batcave_alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_proxy_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_proxy_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_shared_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_shared_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.batcave_alb__proxy_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.batcave_alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.batcave_alb_shared_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.batcave_alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.batcave_alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.batcave_alb_proxy_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.batcave_alb_shared_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.batcave_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.batcave_alb_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.batcave_alb_shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_all_nodes_to_other_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_ingress_additional_prefix_lists](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_ingress_cidrs_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_ingress_cidrs_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_ingress_pl_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_ingress_pl_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_proxy_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_proxy_ingress_cidrs_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_proxy_ingress_cidrs_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_proxy_ingress_pl_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_proxy_ingress_pl_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_shared_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_shared_ingress_cidrs_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_shared_ingress_cidrs_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_shared_ingress_pl_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.batcave_alb_shared_ingress_pl_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks_node_ingress_alb_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks_node_ingress_alb_shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.https-tg-ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.https-vpc-ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_wafv2_web_acl_association.batcave_alb_shared_cms_waf_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_association.cms_waf_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_association.cms_waf_priv_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [kubectl_manifest.batcave_namespace](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_cluster_role.persistent_volume_management](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.delete_ebs_volumes_lambda](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [null_resource.kubernetes_requirements](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_acm_certificate.acm_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_ami.eks_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy.ssm_patching_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_alias.sops](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_security_groups.delete_ebs_volumes_lambda_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_groups) | data source |
| [aws_wafv2_web_acl.cms_waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/wafv2_web_acl) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_cert_base_domain"></a> [acm\_cert\_base\_domain](#input\_acm\_cert\_base\_domain) | Base domain of the certificate used for the ALB Proxy | `string` | `""` | no |
| <a name="input_alb_deletion_protection"></a> [alb\_deletion\_protection](#input\_alb\_deletion\_protection) | Enable/Disable ALB deletion protection for both ALBs | `bool` | `false` | no |
| <a name="input_alb_drop_invalid_header_fields"></a> [alb\_drop\_invalid\_header\_fields](#input\_alb\_drop\_invalid\_header\_fields) | Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false). The default is false. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type application | `bool` | `true` | no |
| <a name="input_alb_idle_timeout"></a> [alb\_idle\_timeout](#input\_alb\_idle\_timeout) | Default idle request timeout for the ALB | `string` | `"60"` | no |
| <a name="input_alb_private_tags"></a> [alb\_private\_tags](#input\_alb\_private\_tags) | Additional private ALB tags | `map(any)` | `null` | no |
| <a name="input_alb_proxy_ingress_cidrs"></a> [alb\_proxy\_ingress\_cidrs](#input\_alb\_proxy\_ingress\_cidrs) | List of CIDR blocks allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs | `list(string)` | `[]` | no |
| <a name="input_alb_proxy_ingress_prefix_lists"></a> [alb\_proxy\_ingress\_prefix\_lists](#input\_alb\_proxy\_ingress\_prefix\_lists) | List of Prefix List IDs allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs | `list(string)` | `[]` | no |
| <a name="input_alb_proxy_is_internal"></a> [alb\_proxy\_is\_internal](#input\_alb\_proxy\_is\_internal) | If the ALB Proxy should be using internal ips. Defaults to false, because the reason for ALB proxy existing is typically to make it accessible over the Internet | `bool` | `false` | no |
| <a name="input_alb_proxy_restricted_hosts"></a> [alb\_proxy\_restricted\_hosts](#input\_alb\_proxy\_restricted\_hosts) | A list of allowable host for proxy alb | `set(string)` | `[]` | no |
| <a name="input_alb_proxy_subnets"></a> [alb\_proxy\_subnets](#input\_alb\_proxy\_subnets) | List of subnet ids for the ALB Proxy to be deployed into | `list(string)` | `[]` | no |
| <a name="input_alb_public_tags"></a> [alb\_public\_tags](#input\_alb\_public\_tags) | Additional public ALB tags | `map(any)` | `null` | no |
| <a name="input_alb_restricted_hosts"></a> [alb\_restricted\_hosts](#input\_alb\_restricted\_hosts) | A list of allowable host for private alb | `set(string)` | `[]` | no |
| <a name="input_alb_shared_ingress_cidrs"></a> [alb\_shared\_ingress\_cidrs](#input\_alb\_shared\_ingress\_cidrs) | List of CIDR blocks allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs | `list(string)` | `[]` | no |
| <a name="input_alb_shared_ingress_prefix_lists"></a> [alb\_shared\_ingress\_prefix\_lists](#input\_alb\_shared\_ingress\_prefix\_lists) | List of Prefix List IDs allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs | `list(string)` | `[]` | no |
| <a name="input_alb_shared_is_internal"></a> [alb\_shared\_is\_internal](#input\_alb\_shared\_is\_internal) | If the ALB in the shared subnet should be using internal ips. Defaults to false, because the reason for this ALB existing is to make it accessible over the Internet | `bool` | `false` | no |
| <a name="input_alb_shared_restricted_hosts"></a> [alb\_shared\_restricted\_hosts](#input\_alb\_shared\_restricted\_hosts) | A list of allowable host for shared alb | `set(string)` | `[]` | no |
| <a name="input_alb_shared_subnets"></a> [alb\_shared\_subnets](#input\_alb\_shared\_subnets) | List of subnet ids for the ALB in the shared subnet | `list(string)` | `[]` | no |
| <a name="input_alb_ssl_security_policy"></a> [alb\_ssl\_security\_policy](#input\_alb\_ssl\_security\_policy) | ALB SSL Security Policy | `string` | `"ELBSecurityPolicy-TLS13-1-2-Res-2021-06"` | no |
| <a name="input_alb_subnets_by_zone"></a> [alb\_subnets\_by\_zone](#input\_alb\_subnets\_by\_zone) | n/a | `map(string)` | n/a | yes |
| <a name="input_ami_date"></a> [ami\_date](#input\_ami\_date) | n/a | `string` | `""` | no |
| <a name="input_ami_owner_override"></a> [ami\_owner\_override](#input\_ami\_owner\_override) | AMI owner override | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_ami_regex_override"></a> [ami\_regex\_override](#input\_ami\_regex\_override) | Overrides default AMI lookup regex, which grabs latest AMI matching cluster\_version by default | `string` | `""` | no |
| <a name="input_cluster_additional_sg_prefix_lists"></a> [cluster\_additional\_sg\_prefix\_lists](#input\_cluster\_additional\_sg\_prefix\_lists) | n/a | `list(string)` | n/a | yes |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) | `list(string)` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `string` | n/a | yes |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | Map of security group rules to attach to the cluster security group, as you cannot change cluster security groups without replacing the instance | `map(any)` | `{}` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | n/a | `string` | `"1.27"` | no |
| <a name="input_configmap_custom_roles"></a> [configmap\_custom\_roles](#input\_configmap\_custom\_roles) | A custom list of IAM role names to include in the aws-auth configmap | `list(string)` | `[]` | no |
| <a name="input_create_alb_proxy"></a> [create\_alb\_proxy](#input\_create\_alb\_proxy) | Create an Application Load Balancer proxy to live in front of the K8s ALB and act as a proxy from the public Internet | `bool` | `false` | no |
| <a name="input_create_alb_shared"></a> [create\_alb\_shared](#input\_create\_alb\_shared) | Creaes an ALB in the shared subnet | `bool` | `false` | no |
| <a name="input_create_cosign_iam_role"></a> [create\_cosign\_iam\_role](#input\_create\_cosign\_iam\_role) | Flag to create Cosign IAM role | `bool` | `false` | no |
| <a name="input_custom_node_policy_arns"></a> [custom\_node\_policy\_arns](#input\_custom\_node\_policy\_arns) | Custom node policy arns | `set(string)` | `[]` | no |
| <a name="input_custom_node_pools"></a> [custom\_node\_pools](#input\_custom\_node\_pools) | n/a | `any` | `{}` | no |
| <a name="input_enable_hoplimit"></a> [enable\_hoplimit](#input\_enable\_hoplimit) | Enables a IMDSv2 hop limit of 1 on all nodes. Defaults to false | `bool` | `false` | no |
| <a name="input_enable_ssm_patching"></a> [enable\_ssm\_patching](#input\_enable\_ssm\_patching) | Enables Systems Manager to patch nodes | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | `"dev"` | no |
| <a name="input_federated_access_role"></a> [federated\_access\_role](#input\_federated\_access\_role) | Federated access role | `string` | `"ct-ado-batcave-application-admin"` | no |
| <a name="input_force_update_version"></a> [force\_update\_version](#input\_force\_update\_version) | Force update version | `bool` | `true` | no |
| <a name="input_general_node_pool"></a> [general\_node\_pool](#input\_general\_node\_pool) | General node pool, required for hosting core services | `any` | <pre>{<br>  "desired_size": 3,<br>  "instance_type": "c5.2xlarge",<br>  "labels": {<br>    "general": "true"<br>  },<br>  "max_size": 5,<br>  "min_size": 2,<br>  "taints": {},<br>  "use_custom_launch_template": false<br>}</pre> | no |
| <a name="input_github_actions_role"></a> [github\_actions\_role](#input\_github\_actions\_role) | Github actions role | `string` | `"batcave-github-actions-role"` | no |
| <a name="input_grant_delete_ebs_volumes_lambda_access"></a> [grant\_delete\_ebs\_volumes\_lambda\_access](#input\_grant\_delete\_ebs\_volumes\_lambda\_access) | When set to true, a cluster role and permissions will be created to grant the delete-ebs-volumes Lambda access to the PersistentVolumes API. | `bool` | `false` | no |
| <a name="input_host_subnets"></a> [host\_subnets](#input\_host\_subnets) | Override the ec2 instance subnets.  By default, they are launche in private\_subnets, just like the EKS control plane. | `list(any)` | `[]` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | n/a | `string` | `"/delegatedadmin/developer/"` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | n/a | `string` | `"arn:aws:iam::373346310182:policy/cms-cloud-admin/developer-boundary-policy"` | no |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | Instance custom tags | `map(any)` | `null` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | Name of the S3 bucket to send load balancer access logs. | `string` | `null` | no |
| <a name="input_node_https_ingress_cidr_blocks"></a> [node\_https\_ingress\_cidr\_blocks](#input\_node\_https\_ingress\_cidr\_blocks) | List of CIDR blocks to allow into the node over the HTTPs port | `list(string)` | <pre>[<br>  "10.0.0.0/8",<br>  "100.0.0.0/8"<br>]</pre> | no |
| <a name="input_node_labels"></a> [node\_labels](#input\_node\_labels) | The labels to apply to the EKS nodes | `map(string)` | `{}` | no |
| <a name="input_node_schedule_shutdown_hour"></a> [node\_schedule\_shutdown\_hour](#input\_node\_schedule\_shutdown\_hour) | The hour of the day (0-23) the cluster should be shutdown.  If left empty, the cluster will not be stopped. Will run every day otherwise. | `number` | `-1` | no |
| <a name="input_node_schedule_startup_hour"></a> [node\_schedule\_startup\_hour](#input\_node\_schedule\_startup\_hour) | The hour of the day (0-23) the cluster should be restarted.  If left empty, the cluster will not be restarted after shutdown. Will run every weekday otherwise. | `number` | `-1` | no |
| <a name="input_node_schedule_timezone"></a> [node\_schedule\_timezone](#input\_node\_schedule\_timezone) | The timezone of the schedule. Ex: 'America/New\_York', 'America/Chicago', 'America/Denver', 'America/Los\_Angeles', 'Pacific/Honolulu'  See: https://www.joda.org/joda-time/timezones.html | `string` | `"America/New_York"` | no |
| <a name="input_node_taints"></a> [node\_taints](#input\_node\_taints) | The taints to apply to the EKS nodes | `map(string)` | `{}` | no |
| <a name="input_node_volume_delete_on_termination"></a> [node\_volume\_delete\_on\_termination](#input\_node\_volume\_delete\_on\_termination) | Whether the volume should be deleted when the node is terminated.  Defaults to true | `bool` | `true` | no |
| <a name="input_node_volume_size"></a> [node\_volume\_size](#input\_node\_volume\_size) | The size of the volume to use for the nodes.  Defaults to 20 | `number` | `300` | no |
| <a name="input_node_volume_type"></a> [node\_volume\_type](#input\_node\_volume\_type) | The type of volume to use for the nodes.  Defaults to gp2 | `string` | `"gp3"` | no |
| <a name="input_openid_connect_audiences"></a> [openid\_connect\_audiences](#input\_openid\_connect\_audiences) | OpenID Connect Audiences | `list(string)` | `[]` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(any)` | n/a | yes |
| <a name="input_s3_bucket_access_grants"></a> [s3\_bucket\_access\_grants](#input\_s3\_bucket\_access\_grants) | A list of s3 bucket names to grant the cluster roles R/W access to | `list(string)` | `null` | no |
| <a name="input_ssm_iam_patching_policy"></a> [ssm\_iam\_patching\_policy](#input\_ssm\_iam\_patching\_policy) | SSM IAM policy for patching | `string` | `"cms-cloud-ssm-iam-policy-v3"` | no |
| <a name="input_ssm_tag_patch_group"></a> [ssm\_tag\_patch\_group](#input\_ssm\_tag\_patch\_group) | SSM Patching group for instances. For more information: https://cloud.cms.gov/patching-prerequisites | `string` | `"AL2"` | no |
| <a name="input_ssm_tag_patch_window"></a> [ssm\_tag\_patch\_window](#input\_ssm\_tag\_patch\_window) | SSM Patching window for instances. For more information: https://cloud.cms.gov/patching-prerequisites | `string` | `"ITOPS-Wave1-Non-Mktplc-DevTestImpl-MW"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Global resource tags to apply to all resources | `map(any)` | `null` | no |
| <a name="input_use_bottlerocket"></a> [use\_bottlerocket](#input\_use\_bottlerocket) | Use Bottlerocket | `bool` | `false` | no |
| <a name="input_vpc_cidr_blocks"></a> [vpc\_cidr\_blocks](#input\_vpc\_cidr\_blocks) | List of VPC CIDR blocks | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_auth_configmap_yaml"></a> [aws\_auth\_configmap\_yaml](#output\_aws\_auth\_configmap\_yaml) | n/a |
| <a name="output_batcave_alb_proxy_dns"></a> [batcave\_alb\_proxy\_dns](#output\_batcave\_alb\_proxy\_dns) | DNS value of ALB created for proxying request |
| <a name="output_batcave_alb_shared_dns"></a> [batcave\_alb\_shared\_dns](#output\_batcave\_alb\_shared\_dns) | DNS value of ALB created for proxying requests through an ALB in the shared subnet |
| <a name="output_batcave_lb_dns"></a> [batcave\_lb\_dns](#output\_batcave\_lb\_dns) | DNS value of NLB created for routing traffic to apps |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | Arn of cloudwatch log group created |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of cloudwatch log group created |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM role name of the EKS cluster |
| <a name="output_cluster_iam_role_unique_id"></a> [cluster\_iam\_role\_unique\_id](#output\_cluster\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | [deprecated, use cluster\_name] The name of the EKS cluster. Will block on cluster creation until the cluster is really ready |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the EKS cluster. Will block on cluster creation until the cluster is really ready |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | Platform version for the cluster |
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console |
| <a name="output_cluster_security_group_arn"></a> [cluster\_security\_group\_arn](#output\_cluster\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED` |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | The version of the cluster being deployed |
| <a name="output_cosign_iam_role_arn"></a> [cosign\_iam\_role\_arn](#output\_cosign\_iam\_role\_arn) | n/a |
| <a name="output_eks_managed_node_group"></a> [eks\_managed\_node\_group](#output\_eks\_managed\_node\_group) | ARNs of all self managed node groups created |
| <a name="output_fargate_profiles"></a> [fargate\_profiles](#output\_fargate\_profiles) | Map of attribute maps for all EKS Fargate Profiles created |
| <a name="output_node_security_group_arn"></a> [node\_security\_group\_arn](#output\_node\_security\_group\_arn) | Amazon Resource Name (ARN) of the node shared security group |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | ID of the node shared security group |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` |
| <a name="output_private_alb_security_group_id"></a> [private\_alb\_security\_group\_id](#output\_private\_alb\_security\_group\_id) | The Security Group that controls access to the private ALB |
| <a name="output_self_managed_node_groups"></a> [self\_managed\_node\_groups](#output\_self\_managed\_node\_groups) | Map of attribute maps for all self managed node groups created |
| <a name="output_worker_security_group_id"></a> [worker\_security\_group\_id](#output\_worker\_security\_group\_id) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
