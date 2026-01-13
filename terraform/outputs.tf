output "certbot_access_key_id" {
    value = aws_iam_access_key.certbot.id
}

output "certbot_secret_access_key" {
    value = aws_iam_access_key.certbot.secret
    sensitive = true
}

