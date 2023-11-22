#!/bin/sh

ACCOUNT_ID="$1"
IAC_ROLE_NAME="$2"

ROLE_NAME='ssm-instance'
ROLE="--role-name ${ROLE_NAME}"
INSTANCE_PROFILE_NAME='--instance-profile-name ssm'
TRUST_POLICY='trust-policy.json'
PERMISSION_POLICY='permission-policy.json'

# 1. Allow EC2 instances to be managed by SSM

cat > $TRUST_POLICY << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
          "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
aws iam create-role ${ROLE} --assume-role-policy-document file://${TRUST_POLICY}
rm ${TRUST_POLICY}

aws iam attach-role-policy ${ROLE} --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam create-instance-profile ${INSTANCE_PROFILE_NAME}
aws iam add-role-to-instance-profile ${INSTANCE_PROFILE_NAME} ${ROLE}

# 2. Allow IaC to pass the above role to instances

cat > $PERMISSION_POLICY << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
    }
  ]
}
EOF
aws iam put-role-policy --role-name ${IAC_ROLE_NAME} --policy-name pass-${ROLE_NAME}-role --policy-document file://${PERMISSION_POLICY}
rm ${PERMISSION_POLICY}
