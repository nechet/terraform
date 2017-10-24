provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags {
    Name = "Test-LDAP"
  }
  tags {
    Team = "Booters"
  }
  tags {
    User = "andriy.nechet@intapp.com"
  }
}

resource "aws_internet_gateway" "main" {
   vpc_id = "${aws_vpc.vpc.id}"
   tags {
       Name = "{var.internet_gateway.tag_name}"
   }
}


resource "aws_subnet" "subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "172.16.10.0/24"
  availability_zone = "us-east-1a"
  tags {
    Name = "Test-LDAP"
  }
  tags {
    Team = "Booters"
  }
  tags {
    User = "andriy.nechet@intapp.com"
  }
}

resource "aws_route_table" "ldap" {
   vpc_id = "${aws_vpc.vpc.id}"
   route {
       cidr_block = "0.0.0.0/0"
       gateway_id = "${aws_internet_gateway.main.id}"
   }
  tags {
    Name = "Test-LDAP"
  }
  tags {
    Team = "Booters"
  }
  tags {
    User = "andriy.nechet@intapp.com"
  }
}

resource "aws_route_table_association" "ldap_subnet_route_table" {
   subnet_id = "${aws_subnet.subnet.id}"
   route_table_id = "${aws_route_table.ldap.id}"
}

resource "aws_instance" "ldap" {
  ami           = "ami-cd0f5cb6"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet.id}"
  associate_public_ip_address = true
  key_name = "intapp.cloud.dev@akvelon.com"

  vpc_security_group_ids = ["${aws_security_group.ldap_security_group.id}" ]

  tags {
    Name = "Test-LDAP"
  }
  tags {
    Team = "Booters"
  }
  tags {
    User = "andriy.nechet@intapp.com"
  }

  provisioner "remote-exec" {
    inline = [
         "sudo apt-get update -y",
//         "sudo apt-get upgrade -y",
         "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
         "sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' ",
         "sudo apt-get update -y",
//         "apt-cache policy docker-engine",
         "sudo apt-get install -y docker-engine",
         "sudo docker run -d -p 10389:10389 h3nrik/apacheds:2.0.0-M24 "
    ]

    connection {
    	type     = "ssh"
	user     = "ubuntu"
        private_key = "${file("~/microservices-common.pem")}"
    }
  }
}

resource "aws_security_group" "ldap_security_group" {
  description = "ldap security group."

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 10389
      to_port = 10389
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.vpc.id}"
}

output "public_dns" {
  value = "${aws_instance.ldap.public_dns}"
}
output "public_ip" {
  value = "${aws_instance.ldap.public_ip}"
}
