"""Summarizes every JSON object dropped under incoming/ into processed/, triggered by the S3 notification."""

import json
import logging
from typing import Any
from urllib.parse import unquote_plus

import boto3

SOURCE_PREFIX = "incoming/"
TARGET_PREFIX = "processed/"

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def json_type(value: Any) -> str:
    """Name of the JSON type of a decoded value."""
    if isinstance(value, dict):
        return "object"
    if isinstance(value, list):
        return "array"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, str):
        return "string"
    if value is None:
        return "null"
    return "number"


def summarize(key: str, raw: bytes) -> dict[str, Any]:
    """Summary of a JSON document. Raises ValueError when the body is not valid JSON."""
    value = json.loads(raw)
    return {
        "source_key": key,
        "size_bytes": len(raw),
        "top_level_type": json_type(value),
        "item_count": len(value) if isinstance(value, dict | list) else 1,
    }


def process_record(record: dict[str, Any], s3: Any) -> str | None:
    """Summarizes the object of one S3 record. Returns the key written, or None when the key is ignored."""
    bucket = record["s3"]["bucket"]["name"]
    key = unquote_plus(record["s3"]["object"]["key"])
    # The function writes into the bucket that triggers it: never read what it wrote (recursion guard), whatever the
    # notification filter says
    if not key.startswith(SOURCE_PREFIX):
        logger.warning("ignored key outside %s: %s", SOURCE_PREFIX, key)
        return None
    raw = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
    summary = summarize(key, raw)
    target = TARGET_PREFIX + key.removeprefix(SOURCE_PREFIX)
    s3.put_object(Bucket=bucket, Key=target, Body=json.dumps(summary).encode(), ContentType="application/json")
    logger.info("summarized %s into %s", key, target)
    return target


def handler(event: dict[str, Any], context: Any, s3: Any = None) -> dict[str, list[str]]:
    s3 = s3 or boto3.client("s3")
    written = [target for record in event["Records"] if (target := process_record(record, s3))]
    return {"processed": written}
