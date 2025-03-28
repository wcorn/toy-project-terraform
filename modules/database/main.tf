# Database 보안 그룹
resource "aws_security_group" "database" {
  name        = "db-sg-${var.env}"
  description = "Security group for database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "db-sg-${var.env}"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-sg-${var.env}"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.common_tags, {
    Name = "db-sg-${var.env}"
  })
}

# 랜덤 비밀번호 생성 
resource "random_password" "db" {
  length  = 16
  special = false
}
resource "random_password" "db_password_name" {
  length  = 16
  special = false
}
# Secrets Manager를 사용해 DB 접속 정보 저장
resource "aws_secretsmanager_secret" "db_password" {
  name = "db/password-${var.env}-${random_password.db_password_name.result}"
  tags = merge(var.common_tags, {
    Name = "db-password-sm-${var.env}"
  })
}
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db.result
  })
}

# db 인스턴스 생성
resource "aws_db_instance" "mydb" {
  identifier             = "db-${var.env}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = jsondecode(aws_secretsmanager_secret_version.db_password_version.secret_string)["password"]
  db_name                = "test"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot    = true # terraform destroy 편하게 하려는 이유. 실제 환경에서는 절대 금지
  tags = merge(var.common_tags, {
    Name = "db-${var.env}"
  })
}
