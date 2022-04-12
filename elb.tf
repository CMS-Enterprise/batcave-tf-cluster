#resource "aws_lb" "batcave-lb" {
#  name               = "example"
#  load_balancer_type = "application"
#  internal = true

#  subnet_mapping {
#    subnet_id            = aws_subnet.example1.id
#    private_ipv4_address = "10.0.1.15"
#  }

#   subnet_mapping {
#     subnet_id            = aws_subnet.example2.id
#     private_ipv4_address = "10.0.2.15"
#   }
# }

# resource "aws_autoscaling_attachment" "asg_attachment_bar" {
#   autoscaling_group_name = aws_autoscaling_group.asg.id
#   lb_target_group_arn    = aws_lb_target_group.test.arn
# }