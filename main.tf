
/*=============================================================================================================================================================================================
[A] Let's use Terraform to create an EC2 instance for Jenkins, Docker and SonarQube
1--main.tf*/

# resource "aws_instance" "web" {
#   ami                    = "ami-0e83be366243f524a" # change ami id for different region
#   instance_type          = "t2.large"
#   key_name               = "ansible-key" # change key name as per your setup
#   vpc_security_group_ids = [aws_security_group.Jenkins-VM-SG.id]
#   #user_data              = templatefile("./install.sh", {})
#   user_data = file("${path.module}/install.sh", {})

#   tags = {
#     Name = "Docker-Jenkins"
#   }

data "template_file" "install_script" {
  template = file("${path.module}/install.sh")
}

resource "aws_instance" "bastion_server" {
  ami           = "ami-0e83be366243f524a"
  instance_type = "t2.large"
  key_name      = "ansible-key" # change key name as per your setup
  user_data     = data.template_file.install_script.rendered
  vpc_security_group_ids = [aws_security_group.Jenkins-VM-SG.id]

  tags = {
    Name = "Docker-Jenkins-Docker"
  }

  root_block_device {
    volume_size = 40
  }
}

output "instance_ip" {
  value = aws_instance.bastion_server.public_ip
}


resource "aws_security_group" "Jenkins-VM-SG" {
  name        = "Jenkins-VM-SG"
  description = "Allow TLS inbound traffic"

  //3000 for our application , 9000 for Sonarqube, 8080 for Jenkins,443
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-VM-SG"
  }
}
