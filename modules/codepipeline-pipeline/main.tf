locals {
  statements = concat(
  [
    {
      actions   = [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ]
      resources = ["*"]
      effect    = "Allow"
    }
  ],
  var.policy_statements
  )
}

data "aws_iam_policy_document" "assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "project-${var.env}-${var.name}-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

module "artifacts-policy" {
  source            = "../codepipeline-artifacts-policy"
  role_name         = aws_iam_role.role.name
  pipeline_bucket   = aws_s3_bucket.artifacts.arn
  policy_statements = local.statements
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.env}-${var.name}-artifacts"
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.env}-${var.name}"
  role_arn = aws_iam_role.role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.id
    type     = "S3"
  }

  dynamic "stage" {
    for_each = var.stages
    content {
      name = stage.value.name
      action {
        name             = stage.value.name
        category         = stage.value.type
        configuration    = stage.value.config
        owner            = "AWS"
        provider         = stage.value.provider
        run_order        = stage.key + 1
        version          = "1"
        input_artifacts  = stage.value.inputs
        output_artifacts = stage.value.outputs
      }
    }
  }
}