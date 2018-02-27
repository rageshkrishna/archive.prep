#!/bin/bash -e

# Input parameters
export ARTIFACTS_BUCKET="s3://shippable-artifacts"
export VERSION=master
export ZIP_ARTIFACTS_WHITELIST=("node" "reqKick")

set_context() {
  export RES_REPO=$CONTEXT"_repo"
  export ARTIFACT_TAR="/tmp/$CONTEXT-$VERSION.tar.gz"
  export ARTIFACT_ZIP="/tmp/$CONTEXT-$VERSION.zip"
  export S3_BUCKET_DIR="$ARTIFACTS_BUCKET/$CONTEXT/$VERSION/"
  export ARTIFACT_SRC_DIR=$(shipctl get_resource_state $RES_REPO)

  echo "export RES_REPO=$RES_REPO"
  echo "export ARTIFACT_TAR=$ARTIFACT_TAR"
  echo "export S3_BUCKET_DIR=$S3_BUCKET_DIR"
  echo "export ARTIFACT_SRC_DIR=$ARTIFACT_SRC_DIR"
}

create_tar() {
  pushd $ARTIFACT_SRC_DIR
  echo "Creating tar $ARTIFACT_TAR..."
  rm -rf $ARTIFACT_TAR
  git archive --format=tar.gz --output=$ARTIFACT_TAR --prefix=$CONTEXT/ $VERSION
  echo "Successfully created $ARTIFACT_TAR"
  popd
}

push_tar_to_s3() {
  echo "Pushing to S3..."
  aws s3 cp --acl public-read "$ARTIFACT_TAR" "$S3_BUCKET_DIR"
}

create_zip() {
  pushd $ARTIFACT_SRC_DIR
  echo "Creating tar $ARTIFACT_ZIP..."
  rm -rf $ARTIFACT_ZIP
  git archive --format=zip --output=$ARTIFACT_ZIP $VERSION
  echo "Successfully created $ARTIFACT_ZIP"
  popd
}

push_zip_to_s3() {
  echo "Pushing to S3..."
  aws s3 cp --acl public-read "$ARTIFACT_ZIP" "$S3_BUCKET_DIR"
}

is_zip_allowed() {
  local artifact_to_check=$1

  for artifact in "${ZIP_ARTIFACTS_WHITELIST[@]}"; do
    [[ "$artifact" == "$artifact_to_check" ]] && return 0
  done

  return 1
}

main() {
  echo "JOB_TRIGGERED_BY_NAME="$JOB_TRIGGERED_BY_NAME

  IFS='_' read -ra ARR <<< "$JOB_TRIGGERED_BY_NAME"
  export CONTEXT=${ARR[0]}
  echo "Building & pushing $CONTEXT tar..."

  set_context
  create_tar
  push_tar_to_s3
  if is_zip_allowed "$CONTEXT"; then
    create_zip
    push_zip_to_s3
  fi
}

main
