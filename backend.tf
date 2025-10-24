terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "your-key/terraform.tfstate"
    region         = "ap-northeast-1"

    profile = "your-profile"
  }
}