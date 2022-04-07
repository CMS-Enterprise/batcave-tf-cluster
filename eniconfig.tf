resource "time_sleep" "wait_30_secs" {
  create_duration = "30s"
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [module.eks]
}

resource "null_resource" "eni_aws_creds" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${var.cluster_name} --region us-east-1
    EOT
  }
  depends_on = [time_sleep.wait_30_secs]

}

resource "null_resource" "k8eni" {
  for_each = var.vpc_eni_subnets

  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      sh eniconfig.sh ${each.key} ${each.value}
    EOT
  }
  depends_on = [null_resource.eni_aws_creds]

}

resource "null_resource" "k8eni_cleanup" {
  for_each = var.vpc_eni_subnets

  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filter "Name=tag:Name,Values=$CLUSTER_NAME-general" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId]" --output text) --output text
    EOT
  }
  depends_on = [null_resource.k8eni]

}
