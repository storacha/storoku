
# access state for shared resources (primary DNS zone, dev VPC and dev caches)
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "storacha-terraform-state"
    key    = "storacha/${var.appState}/shared.tfstate"
    region = "us-west-2"
  }
}
