data "archive_file" "transform_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/transform.py"
  output_path = "${path.module}/transform.zip"
}

resource "aws_lambda_function" "transform" {
  function_name    = "${local.prefix}-transform"
  filename         = data.archive_file.transform_zip.output_path
  source_code_hash = data.archive_file.transform_zip.output_base64sha256
  handler          = "transform.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.transformed_data.bucket
    }
  }

  layers = [
    "arn:aws:lambda:${var.region}:336392948345:layer:AWSSDKPandas-Python311:17"
  ]
}

resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transform.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_data.arn
}

