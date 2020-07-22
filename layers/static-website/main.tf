provider "aws" {
}

provider "aws" {
  alias = "acm"
}

module "website" {
  source         = "../../modules/website"
  name           = var.name
  bucket_name    = "${var.env}-${var.project_prefix}-${var.project_name}-${var.name}"
  zone           = var.dns_zone
  dns            = var.dns
  error_403_path = "/403.html"
  error_404_path = "/404.html"
  geolocations   = (0 < length(var.geolocations)) ? var.geolocations : null
  providers      = {
    aws     = aws
    aws.acm = aws.acm
  }
}
