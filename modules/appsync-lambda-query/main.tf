module "appsync-datasource-lambda" {
  source = "../appsync-datasource-lambda"
  api = var.api
  name = var.name
  lambda_arn = var.lambda_arn
}
resource "aws_appsync_resolver" "get" {
  api_id            = var.api
  field             = var.name
  type              = "Query"
  data_source       = module.appsync-datasource-lambda.name
  request_template  = file("${path.module}/files/request.vm")
  response_template = file("${path.module}/files/response.vm")
}