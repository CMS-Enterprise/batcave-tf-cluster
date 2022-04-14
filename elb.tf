locals {
  batcave_lb_name           = "${var.cluster_name}-batcave-lb"
  formatted_batcave_lb_name = length(local.batcave_lb_name) > 32 ? "${substr(local.batcave_lb_name, 0, 16)}-${substr(local.batcave_lb_name, length(local.batcave_lb_name) - 15, 32)}" : local.batcave_lb_name
}

# resource "aws_security_group" "batcave-elb-sg" {
#   name        = "${var.cluster_name}-batcave-elb-sg"
#   description = "${var.cluster_name} batcave elb sg"
#   vpc_id      = var.vpc_id
# }

# resource "aws_security_group_rule" "batcave-elb-egress" {
#   description       = "Allow all traffic out"
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.batcave-elb-sg.id
# }

# // Allow 80 so that istio can do the traffic promotion
# // NOTE: This doesn't mean we're allowing unencrypted traffic into the appgate in the cluster, just the load balancer
# resource "aws_security_group_rule" "batcave-elb-http-in" {
#   description       = "Allow HTTP traffic"
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   security_group_id = aws_security_group.batcave-elb-sg.id
#   cidr_blocks       = ["10.0.0.0/8"]
# }

# resource "aws_security_group_rule" "batcave-elb-https-in" {
#   description       = "Allow HTTPS traffic"
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   security_group_id = aws_security_group.batcave-elb-sg.id
#   cidr_blocks       = ["10.0.0.0/8"]
# }

# module "batcave-elb" {
#   source  = "terraform-aws-modules/elb/aws"
#   name = local.formatted_batcave_lb_name

#   subnets         = var.transport_subnets
#   security_groups = [aws_security_group.batcave-elb-sg.id]
#   internal        = true
#   listener = [
#     {
#       instance_port     = "30080"
#       instance_protocol = "TCP"
#       lb_port           = "80"
#       lb_protocol       = "tcp"
#     },
#     {
#       instance_port     = "30443"
#       instance_protocol = "TCP"
#       lb_port           = "443"
#       lb_protocol       = "tcp"
#     },
#     {
#       instance_port     = "30020"
#       instance_protocol = "TCP"
#       lb_port           = "15020"
#       lb_protocol       = "tcp"
#     },
#     {
#       instance_port     = "31443"
#       instance_protocol = "TCP"
#       lb_port           = "15443"
#       lb_protocol       = "tcp"
#     },

#   ]

#   health_check = {
#     target              = "TCP:30020"
#     interval            = 10
#     healthy_threshold   = 2
#     unhealthy_threshold = 6
#     timeout             = 5
#   }

#   access_logs = {}

#   idle_timeout = 500

#   tags = {
#     "kubernetes.io/cluster/${var.cluster_name}" = "shared"
#     "Terraform_Managed"                         = "true"
#   }
# }

# # Attached General Node-Pool to Target Group
# resource "aws_autoscaling_attachment" "general-batcave-workers" {
#   elb   = module.batcave-elb.elb_id
#   autoscaling_group_name = module.eks.self_managed_node_groups.general.autoscaling_group_name
# }

# # Attached Runner Node-Pool to Target Group
# resource "aws_autoscaling_attachment" "runners-batcave-workers" {
#   elb   = module.batcave-elb.elb_id
#   autoscaling_group_name = module.eks.self_managed_node_groups.gitlab-runners.autoscaling_group_name
# }

# resource "aws_security_group_rule" "elb_node" {
#   type                     = "ingress"
#   description              = "Ingress from ELB" 
#   to_port                  = 0
#   from_port                = 0
#   protocol                 = "-1"
#   security_group_id        = module.eks.node_security_group_id
#   source_security_group_id = aws_security_group.batcave-elb-sg.id
# }

# create NLB
resource "aws_lb" "batcave-lb" {
  name               = "batcave-lb"
  load_balancer_type = "network"
  internal = true


  subnets = var.transport_subnets
  enable_deletion_protection = false

  tags = {
    Name = "BatCave-ELB"
    Environment = "Development"
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
    target_group_arn = aws_lb_target_group.batcave-tg-https.arn
  }

}

resource "aws_lb_listener" "batcave-ls-http" {
  load_balancer_arn = aws_lb.batcave-lb.arn
  port              = "15020"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave-tg-https.arn
  }

}

resource "aws_lb_listener" "batcave-ls-http" {
  load_balancer_arn = aws_lb.batcave-lb.arn
  port              = "15443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batcave-tg-https.arn
  }

}

# Create Target Group
resource "aws_lb_target_group" "batcave-tg-https" {
  name     = "batcave-tg-https"
  port     = 30443
  protocol = "TCP"
  vpc_id   = var.vpc_id
  health_check = {
    target              = "TCP:30020"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 6
    timeout             = 5
  }
}

resource "aws_lb_target_group" "batcave-tg-http" {
  name     = "batcave-tg-http"
  port     = 30080
  protocol = "TCP"
  vpc_id   = var.vpc_id
  health_check = {
    target              = "TCP:30020"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 6
    timeout             = 5
  }
}

# Attached General Node-Pool to Target Group
resource "aws_autoscaling_attachment" "general-batcave-workers" {
  lb_target_group_arn    = aws_lb_target_group.batcave-tg-https.arn
  autoscaling_group_name = module.eks.self_managed_node_groups.general.autoscaling_group_name
}

# Attached Runner Node-Pool to Target Group
resource "aws_autoscaling_attachment" "runners-batcave-workers" {
  lb_target_group_arn    = aws_lb_target_group.batcave-tg-https.arn
  autoscaling_group_name = module.eks.self_managed_node_groups.gitlab-runners.autoscaling_group_name
}

# resource "aws_security_group_rule" "elb_node" {
#   type                     = "ingress"
#   description              = "Ingress from ELB" 
#   to_port                  = 0
#   from_port                = 0
#   protocol                 = "-1"
#   security_group_id        = module.eks.node_security_group_id
#   source_security_group_id = aws_security_group.batcave-elb-sg.id
# }