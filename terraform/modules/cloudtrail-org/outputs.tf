output "trail_name" {
  description = "Name of the organization CloudTrail"
  value       = aws_cloudtrail.org.name
}

output "trail_bucket" {
  description = "S3 bucket name for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.bucket
}

