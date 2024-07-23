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

if [ "$API_ID" == "None" ]; then
  # API Gateway 생성
  API_ID=$(aws apigateway import-rest-api --body "file://${OPENAPI_FILE}" --query 'id' --output text --region ${REGION})
  aws apigateway update-rest-api --rest-api-id $API_ID --patch-operations op=replace,path=/name,value="${API_NAME}" --region ${REGION}
else
  # API Gateway 업데이트
  aws apigateway put-rest-api --rest-api-id $API_ID --mode overwrite --body "file://${OPENAPI_FILE}" --region ${REGION}
fi

# API Gateway 경로 및 메서드 가져오기
RESOURCE_IDS=$(aws apigateway get-resources --rest-api-id $API_ID --query "items[].id" --output text --region ${REGION})
for RESOURCE_ID in $RESOURCE_IDS; do
  METHODS=$(aws apigateway get-resource --rest-api-id $API_ID --resource-id $RESOURCE_ID --query "resourceMethods" --output text --region ${REGION})
  for METHOD in $METHODS; do
    # Lambda 통합 추가
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method $METHOD \
      --type AWS_PROXY --integration-http-method POST \
      --uri arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:$(aws sts get-caller-identity --query "Account" --output text):function:${LAMBDA_FUNCTION_NAME}/invocations \
      --region ${REGION}
  done
done

# 배포
aws apigateway create-deployment --rest-api-id $API_ID --stage-name $STAGE_NAME --region ${REGION}
