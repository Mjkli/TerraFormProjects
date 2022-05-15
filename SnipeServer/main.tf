#
# Code was used from:
# https://www.youtube.com/watch?v=SLB_c_ayRMo&ab_channel=freeCodeCamp.org
#


variable "access_key"{}
variable "secret_key"{}


provider "aws"{
    region = "us-west-1"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

#resource "aws_<resource_type>" "name"{
#    config options...
#    key = "value"
#}

# 1. create Vpc
# 2. create Internet Gateway
# 3. Create Custom Route Table
# 4. Create a Subnet
# 5. Associate subnet with route table
# 6. Create security group to allow port 22,80,443
# 7. Create a network inerface with an ip in the subnet that was created in step 4
# 8. Assign an elastic IP to the network interface created in step 7
# 9. Create Ubuntu server and install/enable apache2
# 10. Create an SQL database
# 11. tie it to the Web front end.

# 1. Create VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

# 2. Create Internet gateway
resource "aws_internet_gateway" "Terr_InternetGateway" {
    vpc_id = aws_vpc.main.id
}

# 3. Create custom route Table
resource "aws_route_table" "Terr_Route_table" {
    vpc_id = aws_vpc.main.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.Terr_InternetGateway.id
    }

    tags = {
      "Name" = "Prod"
    }
  
}

# 4. Create Subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-west-1a"
    
    tags = {
      "Name" = "Prod-Subnet"
    }
}

# 5.Associate subnet with route table
resource "aws_route_table_association" "subnet-1-Terr_Route_table" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.Terr_Route_table.id
}

# 6. Create security group to allow port 22,80,443

resource "aws_security_group" "security_group_prod" {
    name = "allow web traffic"
    description = "allows web traffic to webserver"
    vpc_id = aws_vpc.main.id
    
    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        #Ip address that are allowed to come in
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        #Ip address that are allowed to come in
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        #Ip address that are allowed to come in
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]

    }

    tags = {
      Name = "Allow Web and SSH"
    }

  
}

# 7. Create a network inerface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "webserver-nic" {
    subnet_id = aws_subnet.subnet-1.id
    private_ip = "10.0.1.63"
    security_groups = [aws_security_group.security_group_prod.id]  

}

# 8. Create Elastic (Public IP)

resource "aws_eip" "Public-Interface" {
    vpc = true
    network_interface = aws_network_interface.webserver-nic.id
    associate_with_private_ip = aws_network_interface.webserver-nic.private_ip

    depends_on = [aws_internet_gateway.Terr_InternetGateway]
}

#9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "webserver-instance" {
    ami = "ami-0dc5e9ff792ec08e3"
    instance_type = "t2.micro"
    availability_zone = "us-west-1a"

    key_name = "main-key"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.webserver-nic.id
      #delete_on_termination = true
    }

    tags = {
      Name = "WebServer-Terr"
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt upgrade -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo systemctl enable apache2
                sudo bash -c 'echo webserver here! > /var/www/html/index.html'
                EOF

}

# 10. create Mysql database

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

