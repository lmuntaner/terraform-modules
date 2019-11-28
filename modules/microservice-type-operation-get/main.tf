module "operation" {
  source            = "../microservice-type-operation"
  enabled           = var.enabled
  type              = var.type
  family            = "get"
  handler           = ("" != var.handler) ? var.handler : "index.get${var.type.full_upper_name}"
  resolvers         = var.resolvers
  variables         = var.variables
  timeout           = var.timeout
  memory_size       = var.memory_size
  tags              = var.tags
  policy_statements = concat(
    var.policy_statements,
    [
      {
        actions   = ["dynamodb:GetItem", "dynamodb:DescribeTable"]
        resources = [var.type.dynamodb-table.arn, "${var.type.dynamodb-table.arn}/index/*"]
        effect    = "Allow"
      },
    ]
  )
}