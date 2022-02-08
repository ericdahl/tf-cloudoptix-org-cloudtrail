provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Provisioner = "Terraform"
    }
  }
}

module "api_sync" {
  source = "../modules/iam-api-sync"
}

data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}


resource "aws_cloudtrail" "cloud_optix" {
  name                          = "Sophos-Optix-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.optix_cloudtrail.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = true
  depends_on                    = [aws_s3_bucket_policy.optix_cloudtrail]
}

resource "aws_s3_bucket" "optix_cloudtrail" {
  bucket        = "sophos-optix-cloudtrail-${data.aws_caller_identity.current.account_id}"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    id      = "s3flowsdeleteafterNdays"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "optix_cloudtrail" {
  bucket = aws_s3_bucket.optix_cloudtrail.bucket

  depends_on = [aws_s3_bucket.optix_cloudtrail]

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.optix_cloudtrail.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.optix_cloudtrail.arn}/**",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF
}



resource "aws_sns_topic" "optix_cloudtrail" {
  name       = "Sophos-Optix-cloudtrail-s3-sns-topic"
  policy     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OptixSNSpermission20150201",
      "Action": [
        "SNS:Publish"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:Sophos-Optix-cloudtrail-s3-sns-topic",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "${aws_s3_bucket.optix_cloudtrail.arn}"
        }
      }
    }
  ]
}
EOF
  depends_on = [aws_s3_bucket.optix_cloudtrail]
}

resource "aws_sns_topic_subscription" "avid" {
  topic_arn = aws_sns_topic.optix_cloudtrail.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloud_optix.arn
}

resource "aws_s3_bucket_notification" "cloudtrail_optix_create" {
  bucket = aws_s3_bucket.optix_cloudtrail.bucket
  topic {
    id            = "s3eventtriggersSNS"
    topic_arn     = aws_sns_topic.optix_cloudtrail.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json.gz"
  }
}


resource "aws_lambda_function" "cloud_optix" {
  function_name = "Sophos-Optix-cloudtrail-fn"
  filename      = "collector-v2-sns-lambda.zip"
  handler       = "collector-v2-sns-lambda.lambda_handler"
  role          = aws_iam_role.optix_lambda.arn
  memory_size   = "128"
  runtime       = "python3.8"
  timeout       = "120"
  environment {
    variables = {
      CUSTOMER_ID = var.customer_id
      DNS_PREFIX  = "events.optix.sophos.com"
      DNS_PATH    = "s3key/cloudtraillogs"
    }
  }
}

resource "aws_lambda_permission" "avid" {
  statement_id  = "givessnspermissioncloudtrail${data.aws_caller_identity.current.account_id}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloud_optix.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.optix_cloudtrail.arn
}


resource "aws_cloudwatch_log_group" "cloud_optix_lambda" {
  name = "/aws/lambda/Sophos-Optix-cloudtrail-fn"

  retention_in_days = 1
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