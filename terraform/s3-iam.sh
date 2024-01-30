#!/bin/sh

REGION="$1"

S3_VPC_TRUST_POLICY='s3-vpc-trust-policy.json'
cat > $S3_VPC_TRUST_POLICY << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": [
        "arn:aws:s3:::aws-ssm-${REGION}/*",
        "arn:aws:s3:::aws-windows-downloads-${REGION}/*",
        "arn:aws:s3:::amazon-ssm-${REGION}/*",
        "arn:aws:s3:::amazon-ssm-packages-${REGION}/*",
        "arn:aws:s3:::${REGION}-birdwatcher-prod/*",
        "arn:aws:s3:::aws-ssm-distributor-file-${REGION}/*",
        "arn:aws:s3:::aws-ssm-document-attachments-${REGION}/*",
        "arn:aws:s3:::patch-baseline-snapshot-${REGION}/*"
      ]
    }
  ]
}
rm ${S3_VPC_TRUST_POLICY}

SSMInstanceProfileS3Policy
