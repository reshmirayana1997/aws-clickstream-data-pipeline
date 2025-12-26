resource "aws_s3_bucket" "raw_data" {
  bucket = "${local.prefix}-raw-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "transformed_data" {
  bucket = "${local.prefix}-transformed-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_notification" "raw_data_trigger" {
  bucket = aws_s3_bucket.raw_data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.transform.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

