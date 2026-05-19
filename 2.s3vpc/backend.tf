terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket-321123"  # Must be globally unique
    key     = "infra/terraform.tfstate"         # Path inside bucket
    region  = "us-east-1"

    # No dynamodb_table = no state locking
    # ⚠️ Avoid running terraform apply from multiple places simultaneously
  }
}
