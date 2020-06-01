provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "tls_private_key" "elasticsearch_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "elasticsearch_key" {
  key_name   = "elasticsearch_key"
  public_key = tls_private_key.elasticsearch_key.public_key_openssh
}

resource "local_file" "local_ssh_private_key" {
  content         = tls_private_key.elasticsearch_key.private_key_pem
  filename        = "ssh-key-private.pem"
  file_permission = "0400"
}

# Create Security Group
resource "aws_security_group" "elasticsearch-sg" {
  name = "elasticsearch-sg"

  # Inbound for port 9200
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # I am opening port 22 from public internet (0.0.0.0/0), because currently i don't have vpn or bastion host.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # To Allow traffic from Any IP
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create EC2 instance
resource "aws_instance" "elasticsearch_instance" {
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.elasticsearch-sg.id}"]
  key_name               = aws_key_pair.elasticsearch_key.key_name
  subnet_id              = "${var.subnet_id}"
  # Copy bash script into new EC2 instance which will configure elasticsearch
  provisioner "file" {
    source      = "els.sh"
    destination = "/tmp/els.sh"
  } # Change permissions on bash script and execute from ec2-user.
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/els.sh",
      "sudo sh /tmp/els.sh",
    ]
  }

  # Login to the ec2-user with the aws key.
  connection {
    type        = "ssh"
    user        = "${var.users}"
    private_key = tls_private_key.elasticsearch_key.private_key_pem
    host        = self.public_ip
  }

  tags = {
    Name = "Elasticsearch-Server"
  }
}

output "public_ip" {
  value = "${aws_instance.elasticsearch_instance.public_ip}"
}
