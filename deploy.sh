#!/bin/bash

# Usage: ./deploy_api.sh <api_id> <version>

API_ID=$1
VERSION=$2

if [ -z "$API_ID" ] || [ -z "$VERSION" ]; then
  echo "Usage: $0 <api_id> <version>"
  exit 1
fi

# Deploy API for the given version
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name "$VERSION"

# Sleep for 2 seconds to ensure smooth deployment
sleep 2
