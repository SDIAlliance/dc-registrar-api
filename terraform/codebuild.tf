resource "aws_iam_role" "codebuild" {
  name = "${var.namespace}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:*" # FIXME: narrow this down
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild.json
}

locals {
  codebuild_projects = {
    "${var.name}" = {
      git_repo   = "https://github.com/SDIAlliance/nadiki-registrar.git"
      ecr_repo   = module.ecr.repository_url_map["${var.namespace}/registrar"]
      dockerfile = "Dockerfile-prod"
    }
    "ui" = {
      git_repo   = "https://github.com/SDIAlliance/nadiki-ui.git"
      ecr_repo   = module.ecr.repository_url_map["${var.namespace}/ui"]
      dockerfile = "Dockerfile"
    },
    "jupyter-lab" = {
      git_repo   = "https://github.com/SDIAlliance/nadiki-jupyter-lab.git"
      ecr_repo   = module.ecr.repository_url_map["${var.namespace}/jupyter-lab"]
      dockerfile = "Dockerfile"
    }
  }
}

resource "aws_codebuild_project" "default" {
  for_each      = toset(keys(local.codebuild_projects))
  name          = "${var.namespace}-${each.key}-codebuild"
  description   = "Codebuild project for ${local.codebuild_projects[each.key].git_repo}"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.namespace}"
      stream_name = each.key
    }
  }

  source {
    type            = "GITHUB"
    location        = local.codebuild_projects[each.key].git_repo
    git_clone_depth = 1
    buildspec       = templatefile("buildspec.yaml", { repo_url = local.codebuild_projects[each.key].ecr_repo, account_id = data.aws_caller_identity.default.account_id, dockerfile = local.codebuild_projects[each.key].dockerfile })
  }

  source_version = "main"
}
