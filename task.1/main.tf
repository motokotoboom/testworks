provider "aws" {
  region = "eu-west-1"

  access_key = ""

  secret_key = ""
}

resource "aws_key_pair" "ssh_keys" {
  key_name   = "ssh_keys"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "moto-koto-task-1-instance-manager" {
  ami                         = "ami-58d7e821"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.moto-koto-task-1-sg.id}"]
  key_name                    = "${aws_key_pair.ssh_keys.key_name}"
  user_data                   = "#!/usr/bin/env bash\n apt install python-minimal openssh-server -y"
  associate_public_ip_address = 1

  connection {
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  tags {
    Name = "moto-koto-task-1-instance-manager"
  }
}

resource "aws_instance" "moto-koto-task-1-instance-worker" {
  ami                         = "ami-58d7e821"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.moto-koto-task-1-sg.id}"]
  key_name                    = "${aws_key_pair.ssh_keys.key_name}"
  user_data                   = "#!/usr/bin/env bash\n apt install python-minimal openssh-server -y"
  associate_public_ip_address = 1

  connection {
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  tags {
    Name = "moto-koto-task-1-instance-worker"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip}>worker_host && sleep 20&&ansible-playbook ./task1.playbook.yml"
  }
}

resource "aws_security_group" "moto-koto-task-1-sg" {
  name = "moto-koto-task-1-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.0.0/12"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "master_public_ip" {
  value = "${aws_instance.moto-koto-task-1-instance-manager.public_ip}"
}

output "worker_public_ip" {
  value = "${aws_instance.moto-koto-task-1-instance-worker.public_ip}"
}

resource "local_file" "manager_host" {
  content  = "${aws_instance.moto-koto-task-1-instance-manager.public_ip}"
  filename = "${path.module}/manager_host"
}

resource "local_file" "worker_host" {
  content  = "${aws_instance.moto-koto-task-1-instance-worker.public_ip}"
  filename = "${path.module}/worker_host"
}
