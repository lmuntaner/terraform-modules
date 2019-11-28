locals {
  datasources = {
    main   = var.name,
    public = "${var.name}-public",
  }
}

module "lambda" {
  source    = "../lambda"
  enabled   = var.enabled
  file      = var.microservice.file
  name      = var.name
  handler   = var.handler
  variables = merge(
    {
      MICROSERVICE_OUTGOING_TOPIC_ARN = var.microservice.sns_topics.outgoing.arn,
    },
    var.variables,
    var.microservice.variables
  )
  policy_statements = concat(
    var.policy_statements,
    [
      {
        actions   = ["SNS:Publish"]
        resources = [var.microservice.sns_topics.outgoing.arn]
        effect    = "Allow"
      }
    ]
  )
}

resource "aws_appsync_datasource" "datasources" {
  for_each = local.datasources
  api_id           = var.microservice.apis[each.key].id
  name             = replace(each.value, "-", "_")
  type             = "AWS_LAMBDA"
  service_role_arn = var.microservice.apis[each.key].assume_role_arn
  lambda_config {
    function_arn = module.lambda.arn
  }
}

resource "aws_appsync_resolver" "resolvers" {
  for_each          = {for r in var.resolvers: "${r.api}_${r.type}_${r.field}" => r}
  api_id            = var.microservice.apis[each.value.api].id
  field             = each.value.field
  type              = each.value.type
  data_source       = aws_appsync_datasource.datasources[each.value.api].name
  request_template  = templatefile("${path.module}/files/${each.value.mode}-request.vm.tpl", {config: each.value.config, sourcePrefix: ("Query" == each.value.type) ? "" : "${lower(substr(each.value.type, 0, 1))}${substr(each.value.type, 1, length(each.value.type) - 1)}_"})
  response_template = templatefile("${path.module}/files/${each.value.mode}-response.vm.tpl", {config: each.value.config})
}