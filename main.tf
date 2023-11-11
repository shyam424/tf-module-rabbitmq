resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  tags = merge(local.tags, {Name = "${local.name_prefix}-sg"})

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.ssh_ingress_cidr
  }

  ingress {
    description      = "RABBITMQ"
    from_port        = 5672
    to_port          = 25672
    protocol         = "tcp"
    cidr_blocks      = var.sg_ingress_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

#-------------------------------------------------------------------------------------------------------------------
###building of rabbit mq is different from the other DB's ad the code will not work o=in the rabbitmq provided by the aws,
###so we are calling the ansible scripts for rabbitmq and creating the ec2 isntance.
resource "aws_instance" "main" {
  ami                       = data.aws_ami.ami.id
  instance_type             = var.instance_type
  vpc_security_group_ids    = [aws_security_group.main.id]
  subnet_id                 = var.subnet_ids[0]
  tags                      = merge(local.tags, {Name = local.name_prefix })
  user_data                 = file("${path.module}/userdata.sh")

}
#creating dns record for rabbitmq
resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = "rabbitmq-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.main.private_ip]
}

##---------------------------------------------------------------------------------------------------------------------

