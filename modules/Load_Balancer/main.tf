resource "aws_elb" "ALB" {
  name            = "ALB-elb"
  subnets         = [aws_subnet.public.*.id]
  security_groups = [aws_security_group.elb.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = aws_acm_certificate.ALB.arn
  }

  # Define an Elastic IP to associate with the ELB
  resource "aws_eip" "ALB" {
    vpc = true
  }

  # Associate the Elastic IP with the ELB
  resource "aws_elb_attachment" "ALB" {
    elb_id     = aws_elb.ALB.id
    instance_id = aws_instance.ALB.id
    attach_type = "in"
  }

  depends_on = [aws_acm_certificate.ALB]
}
