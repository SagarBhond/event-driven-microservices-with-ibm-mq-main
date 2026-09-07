resource "aws_ssm_parameter" "postgres_user" {
  name  = "/order-saga/POSTGRES_USER"
  type  = "SecureString"
  value = var.db_username

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "postgres_password" {
  name  = "/order-saga/POSTGRES_PASSWORD"
  type  = "SecureString"
  value = var.db_password

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "mq_password" {
  name  = "/order-saga/MQ_PASSWORD"
  type  = "SecureString"
  value = "ChangeMe123!"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "mq_admin_password" {
  name  = "/order-saga/MQ_ADMIN_PASSWORD"
  type  = "SecureString"
  value = "ChangeMe123!"

  lifecycle {
    ignore_changes = [value]
  }
}
