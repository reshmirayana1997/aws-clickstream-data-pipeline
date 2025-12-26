resource "aws_glue_catalog_database" "clickstream_db" {
  name = "${replace(local.prefix, "-", "_")}_db"
}

resource "aws_glue_crawler" "transformed_crawler" {
  name          = "${local.prefix}-crawler"
  database_name = aws_glue_catalog_database.clickstream_db.name
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.transformed_data.bucket}/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  schedule = "cron(0 * * * ? *)"
}

