# create Batcave ALB that forwards traffic to K8s
resource "aws_lb" "batcave_alb" {
  name                       = "${var.cluster_name}-alb"
  load_balancer_type         = "application"
  internal                   = true
  security_groups            = [aws_security_group.batcave_alb.id]
  enable_deletion_protection = var.alb_deletion_protection
  drop_invalid_header_fields = var.alb_drop_invalid_header_fields

  idle_timeout = var.alb_idle_timeout

  dynamic "subnet_mapping" {
    for_each = var.alb_subnets_by_zone
    content {
      subnet_id = subnet_mapping.value
    }
  }

  access_logs {
    bucket  = var.logging_bucket
    enabled = true
  }

  tags = merge(
    var.tags,
    var.alb_private_tags,
  )
}

# Listener HTTPS
resource "aws_lb_listener" "batcave_alb_https" {
  load_balancer_arn = aws_lb.batcave_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_security_policy
  dynamic "default_action" {
    for_each = length(var.alb_restricted_hosts) == 0 ? ["forward all request"] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.batcave_alb_https.arn
    }
  }
  dynamic "default_action" {
    for_each = length(var.alb_restricted_hosts) > 0 ? ["deny all request"] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body = "Unacceptable Host"
        status_code  = "403"
      }
    }
  }
  certificate_arn = data.aws_acm_certificate.acm_certificate[0].arn
  tags = {
    Name        = "${var.cluster_name}-https-tg"
    Environment = var.environment
  }
}
# Listener Rule
resource "aws_lb_listener_rule" "batcave_alb_https" {
  for_each     = var.alb_restricted_hosts
  listener_arn = aws_lb_listener.batcave_alb_https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave_alb_https.arn
  }
  condition {
    host_header {
      values = [each.value]
    }
  }
}


# Redirect from HTTP to HTTPS
resource "aws_lb_listener" "batcave_alb_http" {
  load_balancer_arn = aws_lb.batcave_alb.arn
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
    Name        = "${var.cluster_name}-http"
    Environment = var.environment
  }
}

# Create HTTPS Target Group
resource "aws_lb_target_group" "batcave_alb_https" {
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

resource "aws_lb_target_group" "batcave_alb_http" {
  name_prefix          = substr(var.cluster_name, 0, 6)
  port                 = 30080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
    interval            = 30
    path                = "/healthz/ready"
    protocol            = "HTTP"
    port                = "30020"
  }
}

# Security Groups
resource "aws_security_group" "batcave_alb" {
  description            = "${var.cluster_name}-alb-proxy allow inbound"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "batcave_alb_egress" {
  security_group_id = aws_security_group.batcave_alb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "batcave_alb_ingress_pl_http" {
  security_group_id = aws_security_group.batcave_alb.id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 80
  from_port         = 80
  description       = "Allow inbound Prefix Lists http"
  prefix_list_ids   = var.cluster_additional_sg_prefix_lists
}

resource "aws_security_group_rule" "batcave_alb_ingress_pl_https" {
  security_group_id = aws_security_group.batcave_alb.id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 443
  from_port         = 443
  description       = "Allow inbound Prefix Lists https"
  prefix_list_ids   = var.cluster_additional_sg_prefix_lists
}

resource "aws_security_group_rule" "batcave_alb_ingress_cidrs_http" {
  count             = length(var.node_https_ingress_cidr_blocks) > 0 ? 1 : 0
  security_group_id = aws_security_group.batcave_alb.id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 80
  from_port         = 80
  description       = "Allow inbound Prefix Lists http"
  cidr_blocks       = var.node_https_ingress_cidr_blocks
}

resource "aws_security_group_rule" "batcave_alb_ingress_cidrs_https" {
  count             = length(var.node_https_ingress_cidr_blocks) > 0 ? 1 : 0
  security_group_id = aws_security_group.batcave_alb.id
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 443
  from_port         = 443
  description       = "Allow inbound Prefix Lists https"
  cidr_blocks       = var.node_https_ingress_cidr_blocks
}

resource "aws_wafv2_web_acl_association" "cms_waf_priv_assoc" {
  resource_arn = aws_lb.batcave_alb.arn
  web_acl_arn  = data.aws_wafv2_web_acl.cms_waf.arn
}
