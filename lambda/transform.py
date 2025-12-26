import json
import os
import boto3
import awswrangler as wr
import pandas as pd
from urllib.parse import unquote_plus

s3 = boto3.client('s3')

def handler(event, context):
    dest_bucket = os.environ['DEST_BUCKET']
    
    for record in event['Records']:
        src_bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        
        response = s3.get_object(Bucket=src_bucket, Key=key)
        raw_content = response['Body'].read().decode('utf-8')
        
        records = []
        for line in raw_content.strip().split('\n'):
            if line:
                try:
                    records.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        
        if not records:
            continue
        
        df = pd.DataFrame(records)
        
        drop_cols = ['raw_user_agent', 'internal_tracking_id']
        df = df.drop(columns=[c for c in drop_cols if c in df.columns], errors='ignore')
        
        if 'timestamp' in df.columns:
            df['event_date'] = pd.to_datetime(df['timestamp']).dt.strftime('%Y-%m-%d')
        
        path_parts = key.split('/')
        partition_path = '/'.join([p for p in path_parts if '=' in p])
        
        output_path = f"s3://{dest_bucket}/{partition_path}/"
        
        wr.s3.to_parquet(
            df=df,
            path=output_path,
            dataset=True,
            mode="append"
        )
    
    return {'statusCode': 200, 'body': 'done'}

