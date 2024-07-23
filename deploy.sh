#!/bin/bash

set -e

# 변수 설정
REGION="ap-northeast-2"
LAMBDA_FUNCTION_NAME="user"
API_NAME="user-gateway"
STAGE_NAME="prod"
OPENAPI_FILE="openapi.json"

# API Gateway ID 가져오기
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${API_NAME}'].id" --output text --region ${REGION})

echo "API_ID: ${API_ID}"

if [ -z "$API_ID" ] || [ "$API_ID" == "None" ]; then
  echo "Creating new API Gateway..."
  # API Gateway 생성
  API_ID=$(aws apigateway import-rest-api --body "fileb://${OPENAPI_FILE}" --query 'id' --output text --region ${REGION})
  aws apigateway update-rest-api --rest-api-id $API_ID --patch-operations op=replace,path=/name,value="${API_NAME}" --region ${REGION}
else
  echo "Updating existing API Gateway..."
  # API Gateway 업데이트
  aws apigateway put-rest-api --rest-api-id $API_ID --mode overwrite --body "fileb://${OPENAPI_FILE}" --region ${REGION}
fi

echo "Updated API_ID: ${API_ID}"

# API Gateway 경로 및 메서드 가져오기
RESOURCE_IDS=$(aws apigateway get-resources --rest-api-id $API_ID --query "items[].id" --output text --region ${REGION})
echo "RESOURCE_IDS: ${RESOURCE_IDS}"

for RESOURCE_ID in $RESOURCE_IDS; do
  echo "Processing RESOURCE_ID: ${RESOURCE_ID}"
  METHODS=$(aws apigateway get-resource --rest-api-id $API_ID --resource-id $RESOURCE_ID --query "resourceMethods.keys()" --output text --region ${REGION})
  echo "METHODS for RESOURCE_ID ${RESOURCE_ID}: ${METHODS}"
  for METHOD in $METHODS; do
    echo "Adding integration for METHOD: ${METHOD} on RESOURCE_ID: ${RESOURCE_ID}"
    # Lambda 통합 추가
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method $METHOD \
      --type AWS_PROXY --integration-http-method POST \
      --uri arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:$(aws sts get-caller-identity --query "Account" --output text):function:${LAMBDA_FUNCTION_NAME}/invocations \
      --region ${REGION}
  done
done

# 배포
aws apigateway create-deployment --rest-api-id $API_ID --stage-name $STAGE_NAME --region ${REGION}
