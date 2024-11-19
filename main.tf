resource "aws_api_gateway_rest_api" "semver" {
  name = "semver-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }


  body = templatefile("${path.module}/openapi.yml", {
    invokeUrl      = "https://example.execute-api.${data.aws_region.current.name}.amazonaws.com"
    aws_region     = data.aws_region.current.name
    aws_account_id = data.aws_caller_identity.current.account_id
    lambda_name    = "semverHandler"
  })

}


data "archive_file" "handlerv1_function" {
  type        = "zip"
  source_file = "indexv1.js"
  output_path = "indexv1.zip"
}

data "archive_file" "handlerv2_function" {
  type        = "zip"
  source_file = "indexv2.js"
  output_path = "indexv2.zip"
}



resource "aws_lambda_function" "semver_lambda_v1" {
  filename         = data.archive_file.handlerv1_function.output_path
  function_name    = "semverHandlerV1"
  handler          = "indexv1.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.handlerv1_function.output_sha256
}

resource "aws_lambda_function" "semver_lambda_v2" {
  filename         = data.archive_file.handlerv2_function.output_path
  function_name    = "semverHandlerV2"
  handler          = "indexv2.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.handlerv2_function.output_sha256
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_api_gateway_deployment" "semver_deployment_v1" {
  rest_api_id = aws_api_gateway_rest_api.semver.id
  depends_on  = [aws_api_gateway_rest_api.semver]
}

resource "aws_api_gateway_deployment" "semver_deployment_v2" {
  rest_api_id = aws_api_gateway_rest_api.semver.id
  depends_on  = [aws_api_gateway_rest_api.semver]
}

resource "aws_api_gateway_stage" "v1" {
  rest_api_id   = aws_api_gateway_rest_api.semver.id
  stage_name    = "v1"
  deployment_id = aws_api_gateway_deployment.semver_deployment_v1.id

  variables = {
    lambdaversionx = "v1"
  }
}

resource "aws_api_gateway_stage" "v2" {
  rest_api_id   = aws_api_gateway_rest_api.semver.id
  stage_name    = "v2"
  deployment_id = aws_api_gateway_deployment.semver_deployment_v2.id

  variables = {
    lambdaversion = "v2"
  }
}


resource "aws_lambda_permission" "api_gateway_invoke_v1" {
  statement_id  = "AllowAPIGatewayInvokeV1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.semver_lambda_v1.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.semver.execution_arn}/*"
}

resource "aws_lambda_permission" "api_gateway_invoke_v2" {
  statement_id  = "AllowAPIGatewayInvokeV2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.semver_lambda_v2.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.semver.execution_arn}/*"
}


output "v1_stage_url" {
  value = "https://${aws_api_gateway_rest_api.semver.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/v1/starwars/forceusers"
}

output "v2_stage_url" {
  value = "https://${aws_api_gateway_rest_api.semver.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/v2/starwars/forceusers"
}
