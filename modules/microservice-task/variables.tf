variable "name" {
  type    = string
  default = ""
}
variable "enabled" {
  type    = bool
  default = true
}
variable "definition_vars" {
  type    = map(string)
  default = {}
}
variable "variables" {
  type    = map(string)
  default = {}
}
variable "definition_file" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "policy_statements" {
  type = list(object({
    actions = list(string),
    resources = list(string),
    effect = string,
  }))
}
variable "image" {
  type = string
}
variable "cluster" {
  type = string
}
variable "subnets" {
  type    = list(string)
  default = []
}
variable "microservice" {
  type = object({
    name = string,
    env = string,
    file = string,
    prefix = string,
    table_prefix = string,
    apis = map(
    object({
      id = string,
      assume_role_arn = string,
    }),
    ),
    sns_topics = map(
    object({
      arn = string,
    })
    ),
    variables = map(string),
    dynamodb_tables = map(
    object({
      arn = string,
    })
    ),
  })
}