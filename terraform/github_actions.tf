resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  lifecycle {
    ignore_changes = [
      thumbprint_list,
      tags,
      tags_all,
    ]
  }
}

output "github_actions_role_arn" {
  description = "Role ARN to store in the GitHub AWS_ROLE_ARN secret"
  value       = "arn:aws:iam::882040517001:role/github-actions-order-saga-role"
}
