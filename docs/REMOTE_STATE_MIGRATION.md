# Ireland Terraform Remote-State Migration

**Status: Prepared, not migrated.** This document describes an intentional, reviewed operation for the existing Ireland deployment. No application infrastructure resources should be recreated. Do not apply Terraform against an empty state.

## Scope and prerequisites

- AWS account: `253650698585`
- Region: `eu-west-1`
- Existing Terraform directory on the engineer's workstation: `~/nase-842/terraform-eu-west-1`
- Existing workspace: `default`
- Previously verified tracked addresses: **44**
- Expected dedicated state bucket: `nase842-eldeeb-tfstate-253650698585-eu-west-1`
- State object key: `nase842/ireland/terraform.tfstate`
- State lock: S3 native `.tflock` object with `use_lockfile = true`

**Before writing anything:** obtain authorization to create a dedicated bucket in the shared AWS account. Never reconfigure another engineer's state bucket. Confirm that no Terraform process is running for this environment. Verify the profile points to account `253650698585`. The existing state backup must be stored privately and not committed, uploaded, or pasted into chats.

## Phase 1: Read-only checks

Run from the machine holding the **existing** local state:

```bash
cd ~/nase-842/terraform-eu-west-1
export AWS_PROFILE=task17

aws sts get-caller-identity --query Account --output text
terraform workspace show
terraform state list | wc -l
stat -c '%n | %s bytes | permissions: %a' "$HOME/.nase842-state-backups/ireland-before-s3.tfstate"
```

Expected account `253650698585`, workspace `default`, and **44** addresses. The backup is a sensitive file, and only its metadata should be shared.

To preview the dedicated bucket setup with no writes, from a checkout of this repository:

```bash
AWS_PROFILE=task17 bash scripts/bootstrap-ireland-state-bucket.sh --check
```

## Phase 2: Provision the dedicated bucket (AWS writes)

Only after authorization and review:

```bash
AWS_PROFILE=task17 bash scripts/bootstrap-ireland-state-bucket.sh --provision
```

This configures a dedicated private S3 bucket with ownership controls, versioning, SSE-S3 default encryption, blocked public access, a deny-insecure-transport policy, and tags. The script does not migrate state or perform any Terraform apply. The bucket is deliberately managed *outside* the application's Ireland Terraform state.

Verify the destination:

```bash
aws s3api get-bucket-versioning \
  --bucket nase842-eldeeb-tfstate-253650698585-eu-west-1 \
  --query Status --output text

aws s3api get-public-access-block \
  --bucket nase842-eldeeb-tfstate-253650698585-eu-west-1

aws s3api get-bucket-encryption \
  --bucket nase842-eldeeb-tfstate-253650698585-eu-west-1
```

Make sure the remote state object **does not already exist** before a first migration:

```bash
aws s3api head-object \
  --bucket nase842-eldeeb-tfstate-253650698585-eu-west-1 \
  --key nase842/ireland/terraform.tfstate
```

For a brand-new destination, `head-object` should report that the object is absent (typically HTTP 404). If it exists or access is denied, **STOP** and investigate. Do not overwrite it.

## Phase 3: Migrate the actual existing state

The `backend.tf` file must be present in **the same working directory holding the existing local state**. It is currently prepared in the `remote-state-bootstrap` branch. Update the local working directory carefully without replacing or deleting its `terraform.tfstate` file or `.terraform/` metadata.

**Do not run `terraform init -reconfigure` for this migration**, because that skips copying the existing local state.

From `~/nase-842/terraform-eu-west-1`, with the backup verified, the backend file present, and no other Terraform process running:

```bash
export AWS_PROFILE=task17
terraform init -migrate-state
```

Review Terraform's migration prompt, verify the source is the existing local state and the destination is the dedicated S3 bucket/key, and explicitly confirm the copy. Do not use `-force-copy`.

## Phase 4: Confirm the migration, without applying

```bash
terraform workspace show
terraform state list | wc -l
aws s3api head-object \
  --bucket nase842-eldeeb-tfstate-253650698585-eu-west-1 \
  --key nase842/ireland/terraform.tfstate \
  --query '{Size:ContentLength,VersionId:VersionId}' --output table

terraform plan -no-color -detailed-exitcode
echo "Terraform exit code: $?"
```

Expected: `default`, **44** state addresses, an existing versioned S3 state object, and ideally a Terraform exit code of **0** (`No changes`). A code of **2** indicates proposed changes and must be reviewed; code **1** indicates an error.

Never run `terraform apply` or `terraform destroy` as part of state migration. Keep the original backup until the remote state is independently verified, and limit state-object access to authorized operators and a later purpose-built infrastructure CI role.

## Later: infrastructure pipeline access

The S3 backend permissions should be narrowly scoped: `s3:ListBucket` for the bucket, `s3:GetObject`/`s3:PutObject` for the state object, and `s3:GetObject`/`s3:PutObject`/`s3:DeleteObject` for its `.tflock` object. Avoid embedding static AWS credentials or secrets in Terraform files.

The existing frontend/backend GitHub roles are only for deploying application code. Infrastructure CI will need its own properly scoped OIDC role, and PR plans should not receive broad write privileges.

## Separate states by environment

The original Virginia state is a separate workflow and must not be copied into the Ireland key. A later Virginia migration must use its own state key and a separately verified source state.
