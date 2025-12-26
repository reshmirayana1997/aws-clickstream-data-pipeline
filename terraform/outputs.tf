output "firehose_name" {
  value = aws_kinesis_firehose_delivery_stream.clickstream.name
}

output "raw_bucket" {
  value = aws_s3_bucket.raw_data.bucket
}

output "transformed_bucket" {
  value = aws_s3_bucket.transformed_data.bucket
}

output "glue_database" {
  value = aws_glue_catalog_database.clickstream_db.name
}

output "crawler_name" {
  value = aws_glue_crawler.transformed_crawler.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.main.name
}

