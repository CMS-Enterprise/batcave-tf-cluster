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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 1.11.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 1.11.1 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 18.30.2 |
| <a name="module_vpc_cni_irsa"></a> [vpc\_cni\_irsa](#module\_vpc\_cni\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.secretsmanager_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cosign](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.secretsmanager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_service_linked_role.autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_kms_key.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lb.batcave_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.batcave_alb_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.batcave_alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_proxy_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.batcave_alb_proxy_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.batcave_alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.batcave_alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.batcave_alb_proxy_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.batcave_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.batcave_alb_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_all_node_internet_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
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
| [aws_security_group_rule.eks_node_ingress_alb_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.https-tg-ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
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
| <a name="input_addon_kube_proxy_version"></a> [addon\_kube\_proxy\_version](#input\_addon\_kube\_proxy\_version) | This is the image of the kube\_proxy used as addon | `string` | `"v1.22.11-eksbuild.2"` | no |
| <a name="input_addon_vpc_cni_version"></a> [addon\_vpc\_cni\_version](#input\_addon\_vpc\_cni\_version) | This is the image of the CNI pod used in the vpc-cni addon.  For other options, run: aws eks describe-addon-versions --add | `string` | `"v1.11.4-eksbuild.1"` | no |
| <a name="input_alb_deletion_protection"></a> [alb\_deletion\_protection](#input\_alb\_deletion\_protection) | Enable/Disable ALB deletion protection for both ALBs | `bool` | `false` | no |
| <a name="input_alb_drop_invalid_header_fields"></a> [alb\_drop\_invalid\_header\_fields](#input\_alb\_drop\_invalid\_header\_fields) | Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false). The default is false. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type application | `bool` | `true` | no |
| <a name="input_alb_proxy_ingress_cidrs"></a> [alb\_proxy\_ingress\_cidrs](#input\_alb\_proxy\_ingress\_cidrs) | List of CIDR blocks allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs | `list(string)` | `[]` | no |
| <a name="input_alb_proxy_ingress_prefix_lists"></a> [alb\_proxy\_ingress\_prefix\_lists](#input\_alb\_proxy\_ingress\_prefix\_lists) | List of Prefix List IDs allowed to access the ALB Proxy; used to restrict public access to a certain set of IPs | `list(string)` | `[]` | no |
| <a name="input_alb_proxy_is_internal"></a> [alb\_proxy\_is\_internal](#input\_alb\_proxy\_is\_internal) | If the ALB Proxy should be using internal ips.  Defaults to false, because the reason for ALB proxy existing is typically to make it accessible over the Internet | `bool` | `false` | no |
| <a name="input_alb_proxy_subnets"></a> [alb\_proxy\_subnets](#input\_alb\_proxy\_subnets) | List of subnet ids for the ALB Proxy to be deployed into | `list(string)` | `[]` | no |
| <a name="input_alb_subnets_by_zone"></a> [alb\_subnets\_by\_zone](#input\_alb\_subnets\_by\_zone) | n/a | `map(string)` | n/a | yes |
| <a name="input_ami_regex_override"></a> [ami\_regex\_override](#input\_ami\_regex\_override) | Overrides default AMI lookup regex, which grabs latest AMI matching cluster\_version by default | `string` | `""` | no |
| <a name="input_aolytix_role_access"></a> [aolytix\_role\_access](#input\_aolytix\_role\_access) | When set to false, this is not allow kubernetes data to be pulled by the aolytix application | `bool` | `true` | no |
| <a name="input_autoscaling_group_tags"></a> [autoscaling\_group\_tags](#input\_autoscaling\_group\_tags) | Tags to apply to all autoscaling groups created | `map(any)` | `{}` | no |
| <a name="input_block_delete_on_termination"></a> [block\_delete\_on\_termination](#input\_block\_delete\_on\_termination) | n/a | `string` | `"true"` | no |
| <a name="input_block_device_name"></a> [block\_device\_name](#input\_block\_device\_name) | n/a | `string` | `"/dev/xvda"` | no |
| <a name="input_block_encrypted"></a> [block\_encrypted](#input\_block\_encrypted) | n/a | `string` | `"true"` | no |
| <a name="input_block_volume_size"></a> [block\_volume\_size](#input\_block\_volume\_size) | n/a | `number` | `100` | no |
| <a name="input_block_volume_type"></a> [block\_volume\_type](#input\_block\_volume\_type) | n/a | `string` | `"gp2"` | no |
| <a name="input_cluster_additional_sg_prefix_lists"></a> [cluster\_additional\_sg\_prefix\_lists](#input\_cluster\_additional\_sg\_prefix\_lists) | n/a | `list(string)` | n/a | yes |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) | `list(string)` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | n/a | `string` | `"true"` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | n/a | `string` | `"true"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `any` | n/a | yes |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | Map of security group rules to attach to the cluster security group, as you cannot change cluster security groups without replacing the instance | `map(any)` | `{}` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | n/a | `string` | `"1.23"` | no |
| <a name="input_create_alb_proxy"></a> [create\_alb\_proxy](#input\_create\_alb\_proxy) | Create an Application Load Balancer proxy to live in front of the K8s ALB and act as a proxy from the public Internet | `bool` | `false` | no |
| <a name="input_create_cosign_iam_role"></a> [create\_cosign\_iam\_role](#input\_create\_cosign\_iam\_role) | Flag to create Cosign IAM role | `bool` | `false` | no |
| <a name="input_custom_node_pools"></a> [custom\_node\_pools](#input\_custom\_node\_pools) | n/a | `any` | `{}` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | n/a | `string` | `"true"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | `"dev"` | no |
| <a name="input_general_node_pool"></a> [general\_node\_pool](#input\_general\_node\_pool) | General node pool, required for hosting core services | `any` | <pre>{<br>  "desired_size": 3,<br>  "instance_type": "c5.2xlarge",<br>  "labels": {<br>    "general": "true"<br>  },<br>  "max_size": 5,<br>  "min_size": 2,<br>  "taints": {}<br>}</pre> | no |
| <a name="input_general_nodepool_tags"></a> [general\_nodepool\_tags](#input\_general\_nodepool\_tags) | n/a | `any` | `{}` | no |
| <a name="input_github_actions_role_access"></a> [github\_actions\_role\_access](#input\_github\_actions\_role\_access) | When set to false, this is not allow kubernetes data to be pulled by the github actions | `bool` | `true` | no |
| <a name="input_grant_delete_ebs_volumes_lambda_access"></a> [grant\_delete\_ebs\_volumes\_lambda\_access](#input\_grant\_delete\_ebs\_volumes\_lambda\_access) | When set to true, a cluster role and permissions will be created to grant the delete-ebs-volumes Lambda access to the PersistentVolumes API. | `bool` | `false` | no |
| <a name="input_host_subnets"></a> [host\_subnets](#input\_host\_subnets) | Override the ec2 instance subnets.  By default, they are launche in private\_subnets, just like the EKS control plane. | `list(any)` | `[]` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | n/a | `string` | `"/delegatedadmin/developer/"` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | n/a | `string` | `"arn:aws:iam::373346310182:policy/cms-cloud-admin/developer-boundary-policy"` | no |
| <a name="input_instance_tag"></a> [instance\_tag](#input\_instance\_tag) | n/a | `string` | `"Instance custom tag"` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | Name of the S3 bucket to send load balancer access logs. | `string` | `null` | no |
| <a name="input_lt_CustomTag"></a> [lt\_CustomTag](#input\_lt\_CustomTag) | n/a | `string` | `"Launch template custom tag"` | no |
| <a name="input_lt_description"></a> [lt\_description](#input\_lt\_description) | n/a | `string` | `"Default Launch-Template"` | no |
| <a name="input_lt_monitoring_enabled"></a> [lt\_monitoring\_enabled](#input\_lt\_monitoring\_enabled) | ## Monitoring | `string` | `"true"` | no |
| <a name="input_lt_name_prefix"></a> [lt\_name\_prefix](#input\_lt\_name\_prefix) | n/a | `string` | `"eks-lt-"` | no |
| <a name="input_lt_update_default_version"></a> [lt\_update\_default\_version](#input\_lt\_update\_default\_version) | n/a | `string` | `"true"` | no |
| <a name="input_network_int_associate_public_ip_address"></a> [network\_int\_associate\_public\_ip\_address](#input\_network\_int\_associate\_public\_ip\_address) | ## Network Interfaces | `string` | `"false"` | no |
| <a name="input_network_int_delete_on_termination"></a> [network\_int\_delete\_on\_termination](#input\_network\_int\_delete\_on\_termination) | n/a | `string` | `"true"` | no |
| <a name="input_network_interface_tag"></a> [network\_interface\_tag](#input\_network\_interface\_tag) | n/a | `string` | `"Network Interface custom tag"` | no |
| <a name="input_node_https_ingress_cidr_blocks"></a> [node\_https\_ingress\_cidr\_blocks](#input\_node\_https\_ingress\_cidr\_blocks) | List of CIDR blocks to allow into the node over the HTTPs port | `list(string)` | <pre>[<br>  "10.0.0.0/8",<br>  "100.0.0.0/8"<br>]</pre> | no |
| <a name="input_openid_connect_audiences"></a> [openid\_connect\_audiences](#input\_openid\_connect\_audiences) | OpenID Connect Audiences | `list(string)` | `[]` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(any)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-east-1"` | no |
| <a name="input_s3_bucket_access_grants"></a> [s3\_bucket\_access\_grants](#input\_s3\_bucket\_access\_grants) | A list of s3 bucket names to grant the cluster roles R/W access to | `list(string)` | `null` | no |
| <a name="input_transport_proxy_is_internal"></a> [transport\_proxy\_is\_internal](#input\_transport\_proxy\_is\_internal) | Boolean to trigger a public transport proxy ip | `bool` | `true` | no |
| <a name="input_transport_proxy_static_ip"></a> [transport\_proxy\_static\_ip](#input\_transport\_proxy\_static\_ip) | n/a | `bool` | `true` | no |
| <a name="input_volume_tag"></a> [volume\_tag](#input\_volume\_tag) | n/a | `string` | `"Volume custom tag"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_auth_configmap_yaml"></a> [aws\_auth\_configmap\_yaml](#output\_aws\_auth\_configmap\_yaml) | n/a |
| <a name="output_batcave_alb_proxy_dns"></a> [batcave\_alb\_proxy\_dns](#output\_batcave\_alb\_proxy\_dns) | DNS value of NLB created for proxying requests through the application load balancer |
| <a name="output_batcave_lb_dns"></a> [batcave\_lb\_dns](#output\_batcave\_lb\_dns) | DNS value of NLB created for routing traffic to apps |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | Arn of cloudwatch log group created |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of cloudwatch log group created |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM role name of the EKS cluster |
| <a name="output_cluster_iam_role_unique_id"></a> [cluster\_iam\_role\_unique\_id](#output\_cluster\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | Platform version for the cluster |
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console |
| <a name="output_cluster_security_group_arn"></a> [cluster\_security\_group\_arn](#output\_cluster\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED` |
| <a name="output_cosign_iam_role_arn"></a> [cosign\_iam\_role\_arn](#output\_cosign\_iam\_role\_arn) | n/a |
| <a name="output_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | Map of attribute maps for all EKS managed node groups created |
| <a name="output_fargate_profiles"></a> [fargate\_profiles](#output\_fargate\_profiles) | Map of attribute maps for all EKS Fargate Profiles created |
| <a name="output_node_security_group_arn"></a> [node\_security\_group\_arn](#output\_node\_security\_group\_arn) | Amazon Resource Name (ARN) of the node shared security group |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | ID of the node shared security group |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` |
| <a name="output_private_alb_security_group_id"></a> [private\_alb\_security\_group\_id](#output\_private\_alb\_security\_group\_id) | The Security Group that controls access to the private ALB |
| <a name="output_self_managed_node_groups"></a> [self\_managed\_node\_groups](#output\_self\_managed\_node\_groups) | Map of attribute maps for all self managed node groups created |
| <a name="output_worker_security_group_id"></a> [worker\_security\_group\_id](#output\_worker\_security\_group\_id) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
