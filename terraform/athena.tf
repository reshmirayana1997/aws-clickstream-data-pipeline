resource "aws_s3_bucket" "athena_results" {
  bucket = "${local.prefix}-athena-results-${data.aws_caller_identity.current.account_id}"
}

resource "aws_athena_workgroup" "main" {
  name = "${local.prefix}-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }
}

