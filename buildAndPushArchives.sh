#!/bin/bash -e

# Input parameters
export ARTIFACTS_BUCKET="s3://shippable-artifacts"
export VERSION=master

set_context() {
  export RES_REPO="$CONTEXT_repo"
  export ARTIFACT_TAR="/tmp/$CONTEXT-$VERSION.tar.gz"
  export S3_BUCKET_DIR="$ARTIFACTS_BUCKET/$CONTEXT/$VERSION/"
  export ARTIFACT_SRC_DIR=$(shipctl get_resource_state $RES_REPO)

  echo "export RES_REPO=$CONTEXT_repo"
  echo "export ARTIFACT_TAR=$ARTIFACT_TAR"
  echo "export S3_BUCKET_DIR=$S3_BUCKET_DIR"
  echo "export ARTIFACT_SRC_DIR=$ARTIFACT_SRC_DIR"
}

create_tar() {
  pushd $RES_REPO
  echo "Creating tar $ARTIFACT_TAR..."
  rm -rf $ARTIFACT_TAR
  git archive --format=tar.gz --output=$ARTIFACT_TAR --prefix=$CONTEXT/ $VERSION
  echo "Successfully created $ARTIFACT_TAR"
  popd
}

push_to_s3() {
  echo "Pushing to S3..."
  aws s3 cp --acl public-read "$ARTIFACT_TAR" "$S3_BUCKET_DIR"
}

main() {
  echo "JOB_TRIGGERED_BY_NAME="$JOB_TRIGGERED_BY_NAME

  IFS='_' read -ra ARR <<< "$JOB_TRIGGERED_BY_NAME"
  export CONTEXT=${ARR[0]}
  echo "Building & pushing $CONTEXT tar..."

  set_context
  create_tar
  push_to_s3
}

main
