resource "terraform_data" "deployment_verification" {
  triggers_replace = [
    aws_ecs_service.service["producer"].id,
    aws_ecs_service.service["inventory"].id,
    aws_ecs_service.service["payment"].id,
    aws_ecs_service.service["notification"].id,
  ]

  provisioner "local-exec" {
    command     = "${path.module}/verify-deployment.ps1 -AlbDnsName '${aws_lb.main.dns_name}'"
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File"]
  }

  depends_on = [aws_ecs_service.service]
}