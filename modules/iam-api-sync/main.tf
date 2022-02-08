resource "random_uuid" "external_id" {}

locals {
  cloud_optix_aws_account = 195990147830
}

resource "aws_iam_role" "optix" {
  name = "Sophos-Optix-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::${local.cloud_optix_aws_account}:root"
    },
    "Condition": {
      "StringEquals": {
        "sts:ExternalId": "${random_uuid.external_id.result}"
      }
    },
    "Action": [
      "sts:AssumeRole"
    ]
  }]
}

EOF

  tags = {
    Description = "Role that is used by Cloud Optix AWS Account to do API Sync and pull CloudTrail logs from S3"
  }
}

resource "aws_iam_policy" "optix" {
  name   = "Sophos-Optix-read-policy"
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Effect": "Allow",
		"Resource": "*",
		"Action": [
			"elasticfilesystem:DescribeMountTargetSecurityGroups",
			"elasticfilesystem:DescribeMountTargets",
			"sns:ListSubscriptions",
			"s3:GetAccountPublicAccessBlock",
			"ce:GetCostAndUsage",
			"ce:GetCostForecast",
			"ce:GetUsageForecast",
			"eks:List*",
			"detective:ListGraphs",
			"ec2:SearchTransitGatewayRoutes",
		    "ec2:GetTransitGatewayRouteTableAssociations",
			"support:DescribeTrustedAdvisorCheckResult",
			"support:RefreshTrustedAdvisorCheck",
			"ecr:DescribeImages"
		]
	}]
}
EOF
}

resource "aws_iam_role_policy_attachment" "optix_read_only" {
  role       = aws_iam_role.optix.name
  policy_arn = aws_iam_policy.optix.arn
}

resource "aws_iam_role_policy_attachment" "optix_security_audit" {
  role       = aws_iam_role.optix.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}