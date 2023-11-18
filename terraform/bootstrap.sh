#!/bin/sh

REGION="$1"
PROJECT="$2"
ENV="${3:-prod}"

PREFIX="$PROJECT-terraform"

echo 'Creating state bucket...'
aws s3api create-bucket\
    --bucket "$PREFIX-state"\
    --region "$REGION"\
    --create-bucket-configuration LocationConstraint="$REGION"

echo '\nCreating plan bucket...'
aws s3api create-bucket\
    --bucket "$PREFIX-plan"\
    --region "$REGION"\
    --create-bucket-configuration LocationConstraint="$REGION"

echo '\nCreating backend bucket...'
aws s3api create-bucket\
    --bucket "$PREFIX-backend"\
    --region "$REGION"\
    --create-bucket-configuration LocationConstraint="$REGION"

cat > "$ENV.s3.tfbackend" << EOF
bucket         = "$PREFIX-state"
key            = "$ENV/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$PREFIX-lock"
encrypt        = true
EOF
aws s3 cp "$ENV.s3.tfbackend" "s3://$PREFIX-backend/$ENV.s3.tfbackend"
rm "$ENV.s3.tfbackend"

echo '\nCreating lock table...'
aws dynamodb create-table\
    --table-name "$PREFIX-lock"\
    --attribute-definitions AttributeName=LockID,AttributeType=S\
    --key-schema AttributeName=LockID,KeyType=HASH\
    --deletion-protection-enabled\
    --billing-mode PAY_PER_REQUEST\
    --region "$REGION"
