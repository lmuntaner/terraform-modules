variable "env" {
  type = string
}
variable "enabled" {
  type    = bool
  default = true
}
variable "repositories" {
  type = map(object({
  }))
}