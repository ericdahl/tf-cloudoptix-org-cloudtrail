resource "aws_iam_role" "optix_lambda" {

  name = "Sophos-Optix-lambda-logging-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}


EOF
}

resource "aws_iam_policy" "optix_lambda" {
  name   = "Sophos-Optix-lambda-logging-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": "logs:CreateLogGroup",
          "Resource": "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ],
          "Resource": [
              "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
          ]
      }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "optix_lambda" {
  role       = aws_iam_role.optix_lambda.name
  policy_arn = aws_iam_policy.optix_lambda.arn
}