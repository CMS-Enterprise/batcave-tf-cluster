locals {
  batcave_lb_name           = "${var.cluster_name}-batcave-lb"
  formatted_batcave_lb_name = length(local.batcave_lb_name) > 32 ? "${substr(local.batcave_lb_name, 0, 16)}-${substr(local.batcave_lb_name, length(local.batcave_lb_name) - 15, 32)}" : local.batcave_lb_name
}


# create NLB
resource "aws_lb" "batcave-lb" {
  name               = "batcave-lb"
  load_balancer_type = "network"
  internal = true


  subnet_mapping {
    subnet_id = "subnet-07ecb7f1ae2b98f1a"
    private_ipv4_address = "10.223.166.135"
  }
  subnet_mapping {
    subnet_id = "subnet-0898f40360be14ee3"
    private_ipv4_address = "10.223.166.149"
  }
  subnet_mapping {
    subnet_id = "subnet-021d5d13ef6bebdd3"
    private_ipv4_address = "10.223.166.165"
  }

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


# Create Target Group
resource "aws_lb_target_group" "batcave-tg-https" {
  name     = "batcave-tg-https"
  port     = 30443
  protocol = "TCP"
  vpc_id   = var.vpc_id
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
