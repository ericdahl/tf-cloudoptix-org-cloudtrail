provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Provisioner = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}

module "api_sync" {
  source = "../modules/iam-api-sync"
}

resource "null_resource" "add_account" {
  provisioner "local-exec" {
    command = <<EOF
curl \
  -X POST \
  -F tokenId=${var.request_id} \
  -F scriptType=cli \
  -F version=v2 \
  -F flowLogsEnabled=0 \
  -F cloudtrailEnabled=1 \
  -F arn=${module.api_sync.role_arn} \
  -F userAccountId=${data.aws_caller_identity.current.account_id} \
  -F isProduction=FALSE \
  -F accountName="${data.aws_iam_account_alias.current.account_alias}" \
  -F externalId=${module.api_sync.external_id} \
  -F isSpendEnabled=true \
  -F collectorDNSPrefix=events.optix.sophos.com \
  -F defaultRegion=us-east-1 \
  https://optix.sophos.com/public/addAccount


EOF
  }
}
