resource "aws_kinesis_firehose_delivery_stream" "clickstream" {
  name        = "${local.prefix}-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.raw_data.arn

    prefix              = "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    file_extension = ".json"
    buffering_size     = 5
    buffering_interval = 60

    processing_configuration {
      enabled = false
    }
  }
}

