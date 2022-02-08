resource "aws_iam_policy" "cloud_optix_cloudtrail_read" {
  name = "Sophos-Optix-cloudtrail-read-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "${aws_s3_bucket.optix_cloudtrail.arn}/*"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "cloud_optix_cloudtrail_read" {
  role       = module.api_sync.role_name
  policy_arn = aws_iam_policy.cloud_optix_cloudtrail_read.arn
}