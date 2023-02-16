# if you have used ASGs before, that role got auto-created already and you need to import to TF state
resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "Default Service-Linked Role enables access to AWS Services and Resources used or managed by Auto Scaling"
  custom_suffix    = var.cluster_name
}
