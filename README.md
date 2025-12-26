# Clickstream Data Pipeline

Serverless ETL pipeline for processing e-commerce clickstream events using AWS.

## Architecture

```
Kinesis Firehose → S3 (raw/partitioned) → Lambda → S3 (parquet) → Glue Crawler → Athena
```

Events flow through Firehose which batches and writes JSON to S3 with date partitioning. When files land in the raw bucket, Lambda picks them up, converts to Parquet (dropping unnecessary fields), and writes to the transformed bucket. Glue crawler runs hourly to update the catalog so data is queryable via Athena.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Python 3.11 + boto3 (for event generator)

## Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Note the outputs - you'll need the firehose name and glue database for testing.

## Test the Pipeline

### 1. Send sample events

```bash
pip install boto3
python scripts/generate_events.py --stream-name <firehose-name-from-output> --count 100
```

### 2. Wait for processing

Firehose buffers for ~60 seconds, then Lambda transforms. Give it 2-3 minutes.

### 3. Run the crawler

Either wait for the hourly schedule or trigger manually:
```bash
aws glue start-crawler --name <crawler-name-from-output>
```

### 4. Query with Athena

Go to Athena console, select the workgroup from terraform output (`athena_workgroup`), and choose the database (`glue_database`).

## Sample Athena Queries

After the crawler runs, check the Glue console for the actual table name (usually based on the bucket folder structure). Replace `<table_name>` below with the table created by the crawler.

**Count events by type:**
```sql
SELECT event_type, COUNT(*) as cnt
FROM clickstream_pipeline_dev_db.<table_name>
GROUP BY event_type
ORDER BY cnt DESC;
```

**Top pages by views:**
```sql
SELECT page_url, COUNT(*) as views
FROM clickstream_pipeline_dev_db.<table_name>
WHERE event_type = 'page_view'
GROUP BY page_url
ORDER BY views DESC
LIMIT 10;
```

**Events per country:**
```sql
SELECT country, COUNT(*) as events
FROM clickstream_pipeline_dev_db.<table_name>
GROUP BY country;
```

**User sessions (filter by partition):**
```sql
SELECT user_id, session_id, COUNT(*) as actions
FROM clickstream_pipeline_dev_db.<table_name>
WHERE year = '2024' AND month = '12' AND day = '25'
GROUP BY user_id, session_id
ORDER BY actions DESC
LIMIT 20;
```

**Device breakdown:**
```sql
SELECT device_type, browser, COUNT(*) as cnt
FROM clickstream_pipeline_dev_db.<table_name>
GROUP BY device_type, browser
ORDER BY cnt DESC;
```

## Project Structure

```
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── s3.tf
│   ├── kinesis.tf
│   ├── lambda.tf
│   ├── glue.tf
│   ├── athena.tf
│   ├── iam.tf
│   └── outputs.tf
├── lambda/
│   └── transform.py
├── scripts/
│   ├── generate_events.py
│   └── requirements.txt
└── README.md
```

## Cleanup

Empty S3 buckets first (terraform can't delete non-empty buckets):
```bash
aws s3 rm s3://<raw-bucket> --recursive
aws s3 rm s3://<transformed-bucket> --recursive
aws s3 rm s3://<athena-results-bucket> --recursive
```

Then destroy:
```bash
cd terraform
terraform destroy
```

