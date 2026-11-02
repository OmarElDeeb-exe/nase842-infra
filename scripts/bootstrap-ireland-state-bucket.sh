#!/usr/bin/env bash
# Prepare a dedicated S3 bucket for the NASE-842 Ireland Terraform backend.
# Safe by default: no AWS writes unless --provision is explicitly provided.
set -euo pipefail

ACCOUNT_ID="253650698585"
REGION="eu-west-1"
BUCKET="nase842-eldeeb-tfstate-${ACCOUNT_ID}-${REGION}"
PROFILE="${AWS_PROFILE:-task17}"
ACTION="${1:---check}"

if [[ "$ACTION" != "--check" && "$ACTION" != "--provision" ]]; then
  echo "Usage: AWS_PROFILE=task17 bash $0 [--check|--provision]" >&2
  exit 2
fi

ACTUAL_ACCOUNT="$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)"
if [[ "$ACTUAL_ACCOUNT" != "$ACCOUNT_ID" ]]; then
  echo "STOP: AWS account $ACTUAL_ACCOUNT is not the expected account $ACCOUNT_ID." >&2
  exit 1
fi

echo "AWS account: $ACTUAL_ACCOUNT"
echo "S3 region:   $REGION"
echo "State bucket: $BUCKET"

if aws s3api head-bucket --bucket "$BUCKET" --expected-bucket-owner "$ACCOUNT_ID" --profile "$PROFILE" >/dev/null 2>&1; then
  LOCATION="$(aws s3api get-bucket-location --bucket "$BUCKET" --expected-bucket-owner "$ACCOUNT_ID" --profile "$PROFILE" --query LocationConstraint --output text)"
  if [[ "$LOCATION" != "$REGION" ]]; then
    echo "STOP: Existing bucket is in $LOCATION, expected $REGION." >&2
    exit 1
  fi
  echo "Existing bucket is accessible in the expected account/region."
  if [[ "$ACTION" == "--check" ]]; then
    exit 0
  fi
else
  if [[ "$ACTION" == "--check" ]]; then
    echo "No accessible bucket with this exact name. No changes made."
    exit 0
  fi
  echo "Creating a dedicated bucket. This must be authorized in the shared AWS account."
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=$REGION" \
    --profile "$PROFILE"
fi

# A bucket with this name must belong to the expected account.
aws s3api head-bucket --bucket "$BUCKET" --expected-bucket-owner "$ACCOUNT_ID" --profile "$PROFILE"

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true' \
  --profile "$PROFILE"

aws s3api put-bucket-ownership-controls \
  --bucket "$BUCKET" \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]' \
  --profile "$PROFILE"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled \
  --profile "$PROFILE"

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile "$PROFILE"

aws s3api put-bucket-tagging \
  --bucket "$BUCKET" \
  --tagging 'TagSet=[{Key=Project,Value=NASE-842},{Key=ManagedBy,Value=Bootstrap},{Key=Purpose,Value=TerraformRemoteState}]' \
  --profile "$PROFILE"

umask 077
POLICY_FILE="$(mktemp)"
trap 'rm -f "$POLICY_FILE"' EXIT
python3 - "$BUCKET" > "$POLICY_FILE" <<'PY'
import json
import sys
bucket = sys.argv[1]
policy = {
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "DenyInsecureTransport",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:*",
        "Resource": [f"arn:aws:s3:::{bucket}", f"arn:aws:s3:::{bucket}/*"],
        "Condition": {"Bool": {"aws:SecureTransport": "false"}},
    }],
}
print(json.dumps(policy))
PY

aws s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy "file://$POLICY_FILE" \
  --profile "$PROFILE"

echo "Dedicated S3 state bucket configured."
echo "Next: follow docs/REMOTE_STATE_MIGRATION.md to migrate the existing local state."
