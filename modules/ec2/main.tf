resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.medium"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  subnet_id = var.subnet_id

  tags = {
    Name = var.stack_name
  }

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
  EOF
}

resource "aws_security_group" "ec2_security_group" {
  name   = var.stack_name
  vpc_id = var.vpc_id

  ingress {
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
//    cidr_blocks = ["${chomp(data.http.ip.body)}/32"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 8529
    to_port     = 8529
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated" {
  depends_on = ["tls_private_key.default"]
  key_name   = "key-${var.stack_name}-${terraform.workspace}"
  public_key = tls_private_key.default.public_key_openssh
}

resource "local_file" "public_key_openssh" {
  depends_on = ["tls_private_key.default"]
  content    = tls_private_key.default.public_key_openssh
  filename   = local.public_key_filename
}

resource "local_file" "private_key_pem" {
  depends_on = ["tls_private_key.default"]
  content    = tls_private_key.default.private_key_pem
  filename   = local.private_key_filename
}

resource "null_resource" "chmod" {
  depends_on = ["local_file.private_key_pem"]

  provisioner "local-exec" {
    command = "chmod 400 ${local.private_key_filename}"
  }
}

# resource "aws_ebs_volume" "volume" {
#   availability_zone = "${aws_instance.vm.availability_zone}"
#   size = "100"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_volume_attachment" "volume" {
#   skip_destroy = true

#   device_name = "/dev/sdd"
#   volume_id = "${local.use_ebs == true ? var.volume_id : aws_ebs_volume.volume.id}"
#   instance_id = "${aws_instance.vm.id}"
#   provisioner "remote-exec" {
#     inline = [
#       "if [ x`lsblk -ln -o FSTYPE /dev/xvdd` != 'xext4' ] ; then sudo mkfs.ext4 -L datanode /dev/xvdd ; fi",
#       "sudo mkdir /var/lib/arangodb",
#       "sudo mount /dev/xvdd /var/lib/arangodb"
#     ]
#   }

#   provisioner "remote-exec" {
#     when = "destroy"
#     inline = [
#       "sudo umount /var/lib/arangodb"
#     ]
#   }

#   connection {
#     user = "ec2-user"
#     host = "${aws_instance.vm.public_ip}"
#     private_key = "${file(local_file.private_key_pem.filename)}"
#   }
# }
