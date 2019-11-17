locals {
  name_plural       = ("" != var.name_plural) ? var.name_plural : "${var.name}s"
  upper_name        = title(var.name)
  upper_name_plural = title(("" != var.name_plural) ? var.name_plural : "${var.name}s")
  prefix            = "${var.env}-${var.name}"

  operations = {
    events = lookup(var.operations, "events", {})
    list   = lookup(var.operations, "list", {})
    get    = lookup(var.operations, "get", {})
    delete = lookup(var.operations, "delete", {})
    create = lookup(var.operations, "create", {})
    update = lookup(var.operations, "update", {})
  }
  enabled_operations = {
    events = false != lookup(var.operations, "events", false)
    list   = false != lookup(var.operations, "list", false)
    get    = false != lookup(var.operations, "get", false)
    delete = false != lookup(var.operations, "delete", false)
    create = false != lookup(var.operations, "create", false)
    update = false != lookup(var.operations, "update", false)
  }
}

module "lambda-events" {
  source    = "../lambda"
  enabled   = local.enabled_operations.events
  file      = var.file
  name      = "${local.prefix}-events"
  handler   = "index.receiveExternalEvents"
  variables = merge(
    {
      DYNAMODB_TABLE_PREFIX = var.env,
      MICROSERVICE_OUTGOING_TOPIC_ARN = module.sns-outgoing-topic.arn,
    },
    lookup(local.operations.events, "variables", {})
  )
}
module "lambda-list" {
  source    = "../lambda"
  enabled   = local.enabled_operations.list
  file      = var.file
  name      = "${local.prefix}-list"
  handler   = "index.get${local.upper_name_plural}"
  variables = merge(
    {
      DYNAMODB_TABLE_PREFIX = var.env
    },
    lookup(local.operations.list, "variables", {})
  )
  policy_statements = concat(
    [
      {
        actions   = ["dynamodb:GetItem", "dynamodb:ListItem", "dynamodb:DescribeTable", "dynamodb:Scan", "dynamodb:Query"]
        resources = [module.dynamodb-table.arn]
      }
    ],
    lookup(local.operations.list, "policy_statements", [])
  )
}
module "lambda-get" {
  source    = "../lambda"
  enabled   = local.enabled_operations.get
  file      = var.file
  name      = "${local.prefix}-get"
  handler   = "index.get${local.upper_name}"
  variables = merge(
    {
      DYNAMODB_TABLE_PREFIX = var.env
    },
    lookup(local.operations.get, "variables", {})
  )
  policy_statements = concat(
    [
      {
        actions   = ["dynamodb:GetItem", "dynamodb:DescribeTable"]
        resources = [module.dynamodb-table.arn]
      }
    ],
    lookup(local.operations.get, "policy_statements", [])
  )
}
module "lambda-delete" {
  source    = "../lambda"
  enabled   = local.enabled_operations.delete
  file      = var.file
  name      = "${local.prefix}-delete"
  handler   = "index.delete${local.upper_name}"
  variables = merge(
    {
      DYNAMODB_TABLE_PREFIX = var.env,
      MICROSERVICE_OUTGOING_TOPIC_ARN = module.sns-outgoing-topic.arn,
    },
    lookup(local.operations.delete, "variables", {})
  )
  policy_statements = concat(
    [
      {
        actions   = ["dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable", "dynamodb:PutItem"]
        resources = [module.dynamodb-table.arn]
      },
      {
        actions   = ["SNS:Publish"]
        resources = [module.sns-outgoing-topic.arn]
      }
    ],
    lookup(local.operations.delete, "policy_statements", [])
  )
}
module "lambda-create" {
  source = "../lambda"
  enabled = local.enabled_operations.create
  file = var.file
  name = "${local.prefix}-create"
  handler = "index.create${local.upper_name}"
  variables = merge(
    {
      DYNAMODB_TABLE_PREFIX = var.env,
      MICROSERVICE_OUTGOING_TOPIC_ARN = module.sns-outgoing-topic.arn,
    },
    lookup(local.operations.create, "variables", {})
  )
  policy_statements = concat(
    [
      {
        actions   = ["dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable", "dynamodb:PutItem"]
        resources = [module.dynamodb-table.arn]
      },
      {
        actions   = ["SNS:Publish"]
        resources = [module.sns-outgoing-topic.arn]
      }
    ],
    lookup(local.operations.create, "policy_statements", [])
  )
}
module "lambda-update" {
  source = "../lambda"
  enabled = local.enabled_operations.update
  file = var.file
  name = "${local.prefix}-update"
  handler = "index.update${local.upper_name}"
  variables = merge(
    {
      DYNAMODB_TABLE_PREFIX = var.env,
      MICROSERVICE_OUTGOING_TOPIC_ARN = module.sns-outgoing-topic.arn,
    },
    lookup(local.operations.update, "variables", {})
  )
  policy_statements = concat(
    [
      {
        actions   = ["dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:DescribeTable"]
        resources = [module.dynamodb-table.arn]
      },
      {
        actions   = ["SNS:Publish"]
        resources = [module.sns-outgoing-topic.arn]
      }
    ],
    lookup(local.operations.update, "policy_statements", [])
  )
}

module "datasource-lambda-list" {
  source = "../appsync-lambda-datasource"
  enabled = local.enabled_operations.list
  api = var.api
  name = "${local.prefix}-list"
  api_assume_role_arn = module.api-resolvers.api_assume_role_arn
  lambda_arn = module.lambda-list.arn
}
module "datasource-lambda-get" {
  source = "../appsync-lambda-datasource"
  enabled = local.enabled_operations.get
  api = var.api
  name = "${local.prefix}-get"
  api_assume_role_arn = module.api-resolvers.api_assume_role_arn
  lambda_arn = module.lambda-get.arn
}
module "datasource-lambda-delete" {
  source = "../appsync-lambda-datasource"
  enabled = local.enabled_operations.delete
  api = var.api
  name = "${local.prefix}-delete"
  api_assume_role_arn = module.api-resolvers.api_assume_role_arn
  lambda_arn = module.lambda-delete.arn
}
module "datasource-lambda-create" {
  source = "../appsync-lambda-datasource"
  enabled = local.enabled_operations.create
  api = var.api
  name = "${local.prefix}-create"
  api_assume_role_arn = module.api-resolvers.api_assume_role_arn
  lambda_arn = module.lambda-create.arn
}
module "datasource-lambda-update" {
  source = "../appsync-lambda-datasource"
  enabled = local.enabled_operations.update
  api = var.api
  name = "${local.prefix}-update"
  api_assume_role_arn = module.api-resolvers.api_assume_role_arn
  lambda_arn = module.lambda-update.arn
}

module "api-resolvers" {
  source   = "../appsync-lambda-resolvers"
  api      = var.api
  api_name = var.api_name
  name     = "${var.env}-microservice-${var.name}"
  datasources = zipmap(
    [
      "get${local.upper_name_plural}",
      "get${local.upper_name}",
      "delete${local.upper_name}",
      "create${local.upper_name}",
      "update${local.upper_name}",
    ],
    [
      module.datasource-lambda-list.name,
      module.datasource-lambda-get.name,
      module.datasource-lambda-delete.name,
      module.datasource-lambda-create.name,
      module.datasource-lambda-update.name,
    ]
  )
  queries  = merge(
    (false != lookup(local.operations.list, "api", false)) ? zipmap(["get${local.upper_name_plural}"], [{}]) : {},
    (false != lookup(local.operations.get, "api", false)) ? zipmap(["get${local.upper_name}"], [{}]) : {}
  )
  mutations = merge(
    (false != lookup(local.operations.events, "api", false)) ? {receiveExternalEvents = {}} : {},
    (false != lookup(local.operations.delete, "api", false)) ? zipmap(["delete${local.upper_name}"], [{}]) : {},
    (false != lookup(local.operations.create, "api", false)) ? zipmap(["create${local.upper_name}"], [{}]) : {},
    (false != lookup(local.operations.update, "api", false)) ? zipmap(["update${local.upper_name}"], [{}]) : {}
  )
}

module "dynamodb-table" {
  source = "../dynamodb-table"
  name = "${var.env}${local.upper_name}"
}

module "sns-outgoing-topic" {
  source = "../sns-topic"
  name = "${local.prefix}-outgoing"
  sources = [
    module.lambda-events.arn,
    module.lambda-delete.arn,
    module.lambda-create.arn,
    module.lambda-update.arn,
  ]
}

module "sqs-incoming-queue" {
  source = "../sqs-to-lambda"
  name = "${local.prefix}-incoming"
  lambda_arn = module.lambda-events.arn
  lambda_role_name = module.lambda-events.role_name
}