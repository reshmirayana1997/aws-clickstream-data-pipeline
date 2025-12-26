#!/usr/bin/env python3
"""
Simple script to push sample clickstream events to Firehose.
Usage: python generate_events.py --stream-name <firehose-name> --count 100
"""

import argparse
import json
import random
import time
import uuid
from datetime import datetime

import boto3

PAGES = ['/home', '/products', '/cart', '/checkout', '/search', '/product/123', '/product/456', '/category/electronics']
EVENTS = ['page_view', 'click', 'add_to_cart', 'purchase', 'search']
DEVICES = ['mobile', 'desktop', 'tablet']
BROWSERS = ['chrome', 'firefox', 'safari', 'edge']

def generate_event():
    return {
        'event_id': str(uuid.uuid4()),
        'user_id': f'user_{random.randint(1000, 9999)}',
        'session_id': str(uuid.uuid4())[:8],
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'event_type': random.choice(EVENTS),
        'page_url': random.choice(PAGES),
        'device_type': random.choice(DEVICES),
        'browser': random.choice(BROWSERS),
        'country': random.choice(['US', 'UK', 'CA', 'DE', 'FR', 'IN']),
        'raw_user_agent': 'Mozilla/5.0 (will be removed)',
        'internal_tracking_id': 'internal-xyz-123'
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stream-name', required=True, help='Firehose delivery stream name')
    parser.add_argument('--count', type=int, default=50, help='Number of events to send')
    parser.add_argument('--region', default='us-east-1')
    args = parser.parse_args()

    client = boto3.client('firehose', region_name=args.region)
    
    print(f'Sending {args.count} events to {args.stream_name}...')
    
    batch = []
    for i in range(args.count):
        event = generate_event()
        batch.append({'Data': json.dumps(event) + '\n'})
        
        if len(batch) >= 50:
            client.put_record_batch(DeliveryStreamName=args.stream_name, Records=batch)
            batch = []
            print(f'  sent {i+1} events')
            time.sleep(0.1)
    
    if batch:
        client.put_record_batch(DeliveryStreamName=args.stream_name, Records=batch)
    
    print('Done!')

if __name__ == '__main__':
    main()

