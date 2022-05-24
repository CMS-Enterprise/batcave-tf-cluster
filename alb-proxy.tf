data "aws_acm_certificate" "acm_certificate" {
  count       = var.acm_cert_base_domain != "" ? 1 : 0
  domain      = var.acm_cert_base_domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_lb" "batcave_alb_proxy" {
  count = var.create_alb_proxy ? 1 : 0

  name               = "${var.cluster_name}-alb-proxy"
  load_balancer_type = "application"
  internal           = var.alb_proxy_is_internal

  subnets         = var.alb_proxy_subnets
  security_groups = [aws_security_group.batcave_alb_proxy[0].id]

  enable_deletion_protection = false

  tags = {
    Name        = "${var.cluster_name} Application Load Balancer Proxy"
    Environment = var.environment
  }
}

# Listener HTTPS
resource "aws_lb_listener" "batcave_alb_proxy_https" {
  count = var.create_alb_proxy ? 1 : 0

  load_balancer_arn = aws_lb.batcave_alb_proxy[0].arn
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave_alb_proxy_https[0].arn
  }
  certificate_arn = data.aws_acm_certificate.acm_certificate[0].arn
  tags = {
    Name        = "${var.cluster_name}_alb_proxy_https"
    Environment = var.environment
  }
}

# Redirect from HTTP to HTTPS
resource "aws_lb_listener" "batcave_alb_proxy_http" {
  count = var.create_alb_proxy ? 1 : 0

  load_balancer_arn = aws_lb.batcave_alb_proxy[0].arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name        = "${var.cluster_name}_alb_proxy_http"
    Environment = var.environment
  }
}

# Create Target Group
resource "aws_lb_target_group" "batcave_alb_proxy_https" {
  count = var.create_alb_proxy ? 1 : 0

  name_prefix          = substr(var.cluster_name, 0, 6)
  port                 = 443
  protocol             = "HTTPS"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30
  #preserve_client_ip   = false
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "301"
    interval            = 30
    path                = "/aws_alb_healthcheck/${var.cluster_name}-alb-proxy"
    protocol            = "HTTP"
    port                = "80"
  }
}

resource "aws_lb_target_group_attachment" "batcave_alb_proxy_https" {
  for_each         = var.create_alb_proxy ? data.aws_network_interface.batcave_nlb : {}
  target_group_arn = aws_lb_target_group.batcave_alb_proxy_https[0].arn
  target_id        = each.value.private_ip
  port             = 443
}

resource "aws_security_group" "batcave_alb_proxy" {
  count                  = var.create_alb_proxy ? 1 : 0
  description            = "${var.cluster_name}-alb-proxy allow inbound"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "batcave_alb_proxy_ingress_cidrs_http" {
  count             = var.create_alb_proxy && length(var.alb_proxy_ingress_cidrs) > 0 ? 1 : 0
  security_group_id = aws_security_group.batcave_alb_proxy[0].id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 80
  from_port         = 80
  description       = "Allow inbound CIDR blocks http"
  cidr_blocks       = var.alb_proxy_ingress_cidrs
}

resource "aws_security_group_rule" "batcave_alb_proxy_ingress_cidrs_https" {
  count             = var.create_alb_proxy && length(var.alb_proxy_ingress_cidrs) > 0 ? 1 : 0
  security_group_id = aws_security_group.batcave_alb_proxy[0].id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 443
  from_port         = 443
  description       = "Allow inbound CIDR blocks http"
  cidr_blocks       = var.alb_proxy_ingress_cidrs
}

resource "aws_security_group_rule" "batcave_alb_proxy_ingress_pl_http" {
  count             = var.create_alb_proxy && length(var.alb_proxy_ingress_prefix_lists) > 0 ? 1 : 0
  security_group_id = aws_security_group.batcave_alb_proxy[0].id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 80
  from_port         = 80
  description       = "Allow inbound Prefix Lists http"
  prefix_list_ids   = var.alb_proxy_ingress_prefix_lists
}

resource "aws_security_group_rule" "batcave_alb_proxy_ingress_pl_https" {
  count             = var.create_alb_proxy && length(var.alb_proxy_ingress_prefix_lists) > 0 ? 1 : 0
  security_group_id = aws_security_group.batcave_alb_proxy[0].id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 443
  from_port         = 443
  description       = "Allow inbound Prefix Lists https"
  prefix_list_ids   = var.alb_proxy_ingress_prefix_lists
}

resource "aws_security_group_rule" "batcave_alb_proxy_egress" {
  count             = var.create_alb_proxy ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.batcave_alb_proxy[0].id
}
