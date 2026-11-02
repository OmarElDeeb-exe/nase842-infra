# Remote Terraform state for the existing Ireland environment.
# The bucket must be provisioned and the existing local state MIGRATED
# before this backend is used for any plans or applies.
# See docs/REMOTE_STATE_MIGRATION.md.
terraform {
  backend "s3" {
    bucket              = "nase842-eldeeb-tfstate-253650698585-eu-west-1"
    key                 = "nase842/ireland/terraform.tfstate"
    region              = "eu-west-1"
    encrypt             = true
    use_lockfile        = true
    allowed_account_ids = ["253650698585"]
  }
}
