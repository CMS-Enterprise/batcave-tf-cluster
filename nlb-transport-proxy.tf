## This Network Load Balancer exists to proxy traffic from the Transport
## Subnet to the Load Balancer in front of K8s.  For "CMS Reasons", we need
## the cluster to be accessible in two different subnets, and this is the
## solution.
locals {
  batcave_lb_name           = "${var.cluster_name}-batcave-lb"
  formatted_batcave_lb_name = length(local.batcave_lb_name) > 32 ? "${substr(local.batcave_lb_name, 0, 16)}-${substr(local.batcave_lb_name, length(local.batcave_lb_name) - 15, 32)}" : local.batcave_lb_name
}

# create NLB
resource "aws_lb" "batcave_transport" {
  count = var.create_transport_proxy_lb ? 1 : 0

  name               = "${var.cluster_name}-transport"
  load_balancer_type = "network"
  internal           = true

  dynamic "subnet_mapping" {
    for_each = var.transport_subnets_by_zone
    content {
      subnet_id            = subnet_mapping.value
      private_ipv4_address = var.create_nlb_static_ip ? cidrhost(var.transport_subnet_cidr_blocks[var.transport_subnets_by_zone[subnet_mapping.key]], 5) : null
    }
  }

  enable_deletion_protection = var.nlb_deletion_protection

  tags = {
    Name        = "${var.cluster_name}-ELB"
    Environment = var.environment
  }
}

# Listener HTTPS
resource "aws_lb_listener" "batcave_transport_https" {
  count = var.create_transport_proxy_lb ? 1 : 0

  load_balancer_arn = aws_lb.batcave_transport[0].arn
  port              = "443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave_transport_https[0].arn
  }
  tags = {
    Name        = "${var.cluster_name}_transport_https"
    Environment = var.environment
  }
}

# Redirect from HTTP to HTTPS
resource "aws_lb_listener" "batcave_transport_http" {
  count = var.create_transport_proxy_lb ? 1 : 0

  load_balancer_arn = aws_lb.batcave_transport[0].arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave_transport_http[0].arn
  }
  tags = {
    Name        = "${var.cluster_name}_transport_http"
    Environment = var.environment
  }
}

# Create Target Group
resource "aws_lb_target_group" "batcave_transport_https" {
  count = var.create_transport_proxy_lb ? 1 : 0

  name_prefix          = substr(var.cluster_name, 0, 6)
  port                 = 443
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30
  preserve_client_ip   = false
}

resource "aws_lb_target_group" "batcave_transport_http" {
  count = var.create_transport_proxy_lb ? 1 : 0

  name_prefix          = substr(var.cluster_name, 0, 6)
  port                 = 80
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30
  preserve_client_ip   = false
}

resource "aws_lb_target_group_attachment" "batcave_transport_https" {
  for_each         = var.create_transport_proxy_lb ? data.aws_network_interface.batcave_nlb : {}
  target_group_arn = aws_lb_target_group.batcave_transport_https[0].arn
  target_id        = each.value.private_ip
  port             = 443
}

resource "aws_lb_target_group_attachment" "batcave_transport_http" {
  for_each         = var.create_transport_proxy_lb ? data.aws_network_interface.batcave_nlb : {}
  target_group_arn = aws_lb_target_group.batcave_transport_http[0].arn
  target_id        = each.value.private_ip
  port             = 80
}
