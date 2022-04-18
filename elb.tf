locals {
  batcave_lb_name           = "${var.cluster_name}-batcave-lb"
  formatted_batcave_lb_name = length(local.batcave_lb_name) > 32 ? "${substr(local.batcave_lb_name, 0, 16)}-${substr(local.batcave_lb_name, length(local.batcave_lb_name) - 15, 32)}" : local.batcave_lb_name
}


# create NLB
resource "aws_lb" "batcave-lb" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = "network"
  internal = true
  
  dynamic "subnet_mapping" {
    for_each = var.transport_subnets_by_zone
    content {
      subnet_id = subnet_mapping.value
      private_ipv4_address = var.create_nlb_static_ip ? cidrhost(var.transport_subnet_cidr_blocks[var.transport_subnets_by_zone[subnet_mapping.key]],5) : null
    }
  }

  enable_deletion_protection = var.nlb_deletion_protection

  tags = {
    Name = "${var.cluster_name}-ELB"
    Environment = var.environment
  }
}

# Listener HTTPS
resource "aws_lb_listener" "batcave-ls-https" {
  load_balancer_arn = aws_lb.batcave-lb.arn
  port              = "443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave-tg-https.arn
  }
}

# Redirect from HTTP to HTTPS
resource "aws_lb_listener" "batcave-ls-http" {
  load_balancer_arn = aws_lb.batcave-lb.arn
  port              = "80"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave-tg-http.arn
  }
}


# Create Target Group
resource "aws_lb_target_group" "batcave-tg-https" {
  name     = "batcave-tg-https"
  port     = 30443
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "batcave-tg-https" {
  name     = "batcave-tg-http"
  port     = 30080
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

# Attached General Node-Pool to Target Group
resource "aws_autoscaling_attachment" "general-batcave-workers-https" {
  lb_target_group_arn    = aws_lb_target_group.batcave-tg-https.arn
  autoscaling_group_name = module.eks.self_managed_node_groups.general.autoscaling_group_name
}

# Attached Runner Node-Pool to Target Group
resource "aws_autoscaling_attachment" "runners-batcave-workers-https" {
  lb_target_group_arn    = aws_lb_target_group.batcave-tg-https.arn
  autoscaling_group_name = module.eks.self_managed_node_groups.gitlab-runners.autoscaling_group_name
}

# Attached General Node-Pool to Target Group
resource "aws_autoscaling_attachment" "general-batcave-workers-http" {
  lb_target_group_arn    = aws_lb_target_group.batcave-tg-http.arn
  autoscaling_group_name = module.eks.self_managed_node_groups.general.autoscaling_group_name
}

# Attached Runner Node-Pool to Target Group
resource "aws_autoscaling_attachment" "runners-batcave-workers-http" {
  lb_target_group_arn    = aws_lb_target_group.batcave-tg-http.arn
  autoscaling_group_name = module.eks.self_managed_node_groups.gitlab-runners.autoscaling_group_name
}