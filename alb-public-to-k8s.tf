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

  enable_deletion_protection = var.alb_deletion_protection
  drop_invalid_header_fields = var.alb_drop_invalid_header_fields

  idle_timeout = var.alb_proxy_idle_timeout

  access_logs {
    bucket  = var.logging_bucket
    enabled = true
  }

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

# Create HTTPS Target Group
resource "aws_lb_target_group" "batcave_alb_proxy_https" {
  count = var.create_alb_proxy ? 1 : 0

  name_prefix          = substr(var.cluster_name, 0, 6)
  port                 = 30443
  protocol             = "HTTPS"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
    interval            = 30
    path                = "/healthz/ready"
    protocol            = "HTTP" # istio's status-port uses http by default
    port                = "30020"
  }
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

data "aws_wafv2_web_acl" "cms_waf" {
  name  = "RegSamQuickACLEnforcingV2"
  scope = "REGIONAL"
}

resource "aws_wafv2_web_acl_association" "cms_waf_assoc" {
  count        = var.create_alb_proxy ? 1 : 0
  resource_arn = aws_lb.batcave_alb_proxy[0].arn
  web_acl_arn  = data.aws_wafv2_web_acl.cms_waf.arn
}
