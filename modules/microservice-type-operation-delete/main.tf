module "operation" {
  source            = "../microservice-type-operation"
  enabled           = var.enabled
  type              = var.type
  family            = "delete"
  handler           = ("" != var.handler) ? var.handler : "index.delete${var.type.full_upper_name}"
  resolvers         = var.resolvers
  variables         = var.variables
  timeout           = var.timeout
  memory_size       = var.memory_size
  tags              = var.tags
  required_external_operations = var.required_external_operations
  policy_statements = concat(
    var.policy_statements,
    [
      {
        actions   = ["dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:BatchDeleteItem", "dynamodb:Scan", "dynamodb:QueryTable", "dynamodb:DescribeTable", "dynamodb:PutItem"]
        resources = [var.type.dynamodb-table.arn]
        effect    = "Allow"
      },
    ]
  )
}