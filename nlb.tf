resource "aws_lb" "transport" {
  count              = var.create_transport_nlb ? 1 : 0
  name               = "${var.cluster_name}-nlb"
  internal           = true
  load_balancer_type = "network"

  dynamic "subnet_mapping" {
    for_each = var.transport_subnet_cidr_blocks
    content {
      subnet_id            = subnet_mapping.key
      private_ipv4_address = cidrhost(subnet_mapping.value, 5)
    }
  }

  enable_deletion_protection = true

  tags = {
    #TODO Istio tag
    Environment = var.environment
  }
}
