data "terraform_remote_state" "dev" {
  backend = "s3"
  config = {
    bucket = "peter-terraform-state-bn2gz7v3he1rj0ia"
    key    = "dev/terraform/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "prod" {
  backend = "s3"
  config = {
    bucket = "peter-terraform-state-bn2gz7v3he1rj0ia"
    key    = "prod/terraform/terraform.tfstate"
    region = "ap-northeast-2"
  }
}