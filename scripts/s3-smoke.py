#!/usr/bin/env python3
"""S3 round-trip smoke test: create bucket, put/get/list/delete an object.
Usage: s3-smoke.py <endpoint> <access_key> <secret_key> [region]"""
import sys, time
import boto3
from botocore.config import Config

endpoint, ak, sk = sys.argv[1:4]
region = sys.argv[4] if len(sys.argv) > 4 else "us-east-1"
s3 = boto3.client("s3", endpoint_url=endpoint, aws_access_key_id=ak, aws_secret_access_key=sk,
                  region_name=region, config=Config(s3={"addressing_style": "path"}, retries={"max_attempts": 3}))
bucket = f"smoke-{int(time.time())}"
for attempt in range(15):
    try:
        s3.create_bucket(Bucket=bucket)
        break
    except Exception as e:
        print("create_bucket retry:", e)
        time.sleep(3)
else:
    sys.exit("could not create bucket")
s3.put_object(Bucket=bucket, Key="hello.txt", Body=b"hello")
assert s3.get_object(Bucket=bucket, Key="hello.txt")["Body"].read() == b"hello"
assert [o["Key"] for o in s3.list_objects_v2(Bucket=bucket)["Contents"]] == ["hello.txt"]
s3.delete_object(Bucket=bucket, Key="hello.txt")
s3.delete_bucket(Bucket=bucket)
print("S3 smoke OK")
