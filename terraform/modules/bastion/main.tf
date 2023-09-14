resource "aws_security_group" "bastion-sg" {
  name          = "${var.project}-${var.env}-bastion-sg"
  vpc_id        = var.vpc_id
  description   = "${var.project}-${var.env}-bastion-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name  = "${var.project}-${var.env}-bastion-sg"
    Group = "${var.project}"
  }
}

resource "aws_iam_instance_profile" "bastion-profile" {
  name = "${var.project}-${var.env}-bastion-profile"
  role = var.master_role_name
}

resource "aws_instance" "bastion" {
  ami                     = var.bastion_ami_id
  instance_type           = var.bastion_instance_type
  key_name                = var.key_name
  subnet_id               = var.subnet-public-a_id
  vpc_security_group_ids  = [ aws_security_group.bastion-sg.id ]
  ebs_optimized           = true
  iam_instance_profile    = aws_iam_instance_profile.bastion-profile.name
  user_data_base64        = filebase64("${path.module}/userdata.sh")

  credit_specification {
    cpu_credits           = "standard"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.bastion_storage_size
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.project}-${var.env}-bastion"
    Group = "${var.project}"
  }
}
