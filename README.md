# tf-cloudoptix-org-cloudtrail

This is a demonstration of how to set up Sophos Cloud Optix
using Terraform pulling logs from an Organization Trail
and also configuring member accounts.

Pre-requisite: Cloud Optix account set up and working

VPC Flow logs are omitted in this example.

It is split into two sections:
- [org-account](org-account)
  - Terraform to run for the CloudTrail management/main account
  - Resources
    - Role/Policy for Cloud Optix's AWS Account to Assume ("api sync") 
    - CloudTrail Trail with Org enabled
    - S3 bucket for above Trail
    - S3 event notifications to publish to SNS
    - SNS topic for above
    - SNS Subscription to Lambda
    - Lambda (Cloud Optix code) which does a POST to their API with the S3 path
      - They then use their "API Sync" role to pull the JSON gzip file and ingest logs
    - (API call to add account to Cloud Optix)
- [member-account](member-account)
  - Terraform to run in every member account
    - Resources
      - Role/Policy for Cloud Optix's AWS Account to Assume ("api sync")
      - (API call to add account to Cloud Optix)
  - Alternative implementation: CloudFormation StackSet from organization


# TODO:

- figure out error with Lambda not able to load Environment variables due to KKS decrypt