
# create NLB
resource "aws_lb" "batcave_nlb" {
  name               = "${var.cluster_name}-nlb"
  load_balancer_type = "network"
  internal           = true

  dynamic "subnet_mapping" {
    for_each = var.nlb_subnets_by_zone
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name        = "${var.cluster_name}-Shared-NLB"
    Environment = var.environment
  }
}

# Listener HTTPS
resource "aws_lb_listener" "batcave_nlb_https" {
  load_balancer_arn = aws_lb.batcave_nlb.arn
  port              = "443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave_nlb_https.arn
  }
  tags = {
    Name        = "${var.cluster_name}-https-tg"
    Environment = var.environment
  }
}

# Redirect from HTTP to HTTPS
resource "aws_lb_listener" "batcave_nlb_http" {
  load_balancer_arn = aws_lb.batcave_nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave_nlb_http.arn
  }
  tags = {
    Name        = "${var.cluster_name}-http-tg"
    Environment = var.environment
  }
}

# Create Target Group
resource "aws_lb_target_group" "batcave_nlb_https" {
  name_prefix          = substr(var.cluster_name, 0, 6)
  port                 = 30443
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  preserve_client_ip   = false
}

resource "aws_lb_target_group" "batcave_nlb_http" {
  name_prefix          = substr(var.cluster_name, 0, 6)
  port                 = 30080
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  preserve_client_ip   = false
}

# Attached General Node-Pool to Target Groups
#resource "aws_autoscaling_attachment" "general-batcave-workers-https" {
#  lb_target_group_arn    = aws_lb_target_group.batcave_nlb_https.arn
#  autoscaling_group_name = module.eks.self_managed_node_groups.general.autoscaling_group_name
#}
#resource "aws_autoscaling_attachment" "general-batcave-workers-http" {
#  lb_target_group_arn    = aws_lb_target_group.batcave_nlb_http.arn
#  autoscaling_group_name = module.eks.self_managed_node_groups.general.autoscaling_group_name
#}

# Fetch the IP addresses of NLB network interfaces to pass to the transport subnet
data "aws_network_interface" "batcave_nlb" {
  for_each = toset(values(var.nlb_subnets_by_zone))

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.batcave_nlb.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

