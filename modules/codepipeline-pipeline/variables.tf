variable "env" {
  type    = string
  default = "dev"
}
variable "name" {
  type = string
}
variable "stages" {
  type    = list(object({
    type   = string
    name   = string
    config = map(string)
  }))
  default = []
}
variable "policy_statements" {
  type = list(
  object({
    actions   = list(string),
    resources = list(string),
    effect    = string
  })
  )
  default = []
}