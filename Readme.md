# Lambda Trigger Pipeline

## 개요

`lambda-trigger-pipeline` 레포지토리는 `spring-lambda-mvp` 프로젝트의 빌드 및 배포를 자동화하기 위해 설계된 파이프라인입니다. 이 파이프라인은 여러 단계의 GitHub Actions 워크플로우를 통해 코드를 빌드하고, 람다 함수로 배포하며, API Gateway를 설정하여 전체 애플리케이션의 배포를 관리합니다.

## 전체 파이프라인 개요

이 레포지토리는 세 개의 주요 GitHub Actions 워크플로우 파일로 구성되어 있습니다:

1. **`build-and-generate-openapi.yml`**: `spring-lambda-mvp` 레포지토리의 코드를 빌드하고, OpenAPI 스펙을 생성한 후, S3 버킷에 업로드합니다.
2. **`deploy-lambda.yml`**: S3에 업로드된 JAR 파일을 사용하여 AWS Lambda 함수로 배포합니다.
3. **`api-gateway-setup.yml`**: Lambda 함수와 통합된 API Gateway를 설정하고 배포합니다.

## 워크플로우 세부 정보

### 1. build-and-generate-openapi.yml

이 워크플로우는 `spring-lambda-mvp` 레포지토리의 빌드 및 OpenAPI 스펙 생성을 담당합니다. `repository_dispatch` 이벤트(`deploy-trigger` 타입)에 의해 트리거되며, 다음과 같은 작업을 수행합니다:

- **코드 체크아웃**: `spring-lambda-mvp` 레포지토리의 코드를 체크아웃합니다.
- **JDK 17 설정**: Java 17 환경을 설정합니다.
- **프로젝트 빌드**: Gradle을 사용하여 프로젝트를 빌드합니다.
- **Spring Boot 애플리케이션 실행**: 애플리케이션을 실행하고 OpenAPI 스펙을 생성합니다.
- **OpenAPI 및 JAR 파일을 S3에 업로드**: 생성된 OpenAPI 스펙과 빌드된 JAR 파일을 S3 버킷에 업로드합니다.

### 2. deploy-lambda.yml

이 워크플로우는 `build-and-generate-openapi.yml` 워크플로우가 완료된 후 실행됩니다. 다음 작업을 수행합니다:

- **Lambda 함수 존재 여부 확인**: Lambda 함수가 이미 존재하는지 확인합니다.
- **Lambda 함수 생성 또는 업데이트**: S3에서 JAR 파일을 가져와 Lambda 함수를 생성하거나, 기존 함수를 업데이트합니다.

### 3. api-gateway-setup.yml

이 워크플로우는 `deploy-lambda.yml` 워크플로우가 완료된 후 실행됩니다. 다음 작업을 수행합니다:

- **API Gateway 설정**: S3에서 OpenAPI 스펙 파일을 다운로드하고, 이를 바탕으로 API Gateway를 생성 또는 업데이트합니다.
- **API Gateway와 Lambda 통합**: API Gateway 리소스와 메서드를 Lambda 함수와 통합합니다.
- **API Gateway 배포**: 설정이 완료된 API Gateway를 배포합니다.

## 주요 기능

- **자동화된 CI/CD 파이프라인**: 코드의 빌드, 배포, API 설정 등을 자동으로 수행하여 개발 및 배포 속도를 높입니다.
- **AWS Lambda와 API Gateway 통합**: 서버리스 애플리케이션을 쉽게 배포하고 관리할 수 있도록 지원합니다.
- **S3 아티팩트 관리**: 빌드 결과물과 OpenAPI 스펙을 S3에 저장하여 버전 관리 및 배포를 용이하게 합니다.

## 필요 시크릿 설정

이 파이프라인을 사용하려면 레포지토리에 다음과 같은 시크릿을 설정해야 합니다:

- **`PERSONAL_ACCESS_TOKEN`**: `spring-lambda-mvp` 레포지토리에 접근할 수 있는 GitHub Personal Access Token.
- **`AWS_ACCESS_KEY_ID`**: AWS 계정에 대한 접근 키 ID.
- **`AWS_SECRET_ACCESS_KEY`**: AWS 계정에 대한 시크릿 접근 키.
- **`AWS_REGION`**: AWS 리전 정보.
- **`LAMBDA_FUNCTION_NAME`**: 배포할 Lambda 함수의 이름.
- **`S3_BUCKET_NAME`**: 빌드 아티팩트를 저장할 S3 버킷 이름.
- **`DB_URL`**: Spring Boot 애플리케이션의 데이터베이스 URL.
- **`DB_USERNAME`**: 데이터베이스 사용자 이름.
- **`DB_PASSWORD`**: 데이터베이스 비밀번호.
- **`DB_DRIVER`**: 데이터베이스 드라이버.

## 결론

`lambda-trigger-pipeline` 레포지토리는 `spring-lambda-mvp` 프로젝트를 효율적으로 빌드, 배포하고, API Gateway를 통해 외부에 노출하기 위한 자동화된 파이프라인을 제공합니다. 이 파이프라인을 통해 서버리스 애플리케이션의 배포가 간편해지며, 지속적인 통합과 배포(Continuous Integration and Deployment)를 쉽게 관리할 수 있습니다.

