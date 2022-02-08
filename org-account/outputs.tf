output "external_id" {
  value = module.api_sync.external_id
}

output "topic_name" {
  value = aws_sns_topic.optix_cloudtrail.name
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.optix_cloudtrail.bucket
}