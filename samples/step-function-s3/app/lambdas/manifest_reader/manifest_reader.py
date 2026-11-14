"""Reads one file listed in a manifest: one invocation per file, started in parallel by the Distributed Map state."""

import json
import logging
from typing import Any

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class ObjectNotReadyError(Exception):
    """The file listed in the manifest is not there (yet): the state machine retries, the file may still be coming."""


def read_file(s3: Any, bucket: str, key: str) -> dict[str, Any]:
    """Size and item count of a JSON file. Raises ObjectNotReadyError when it is missing, ValueError when invalid."""
    try:
        raw = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
    except s3.exceptions.NoSuchKey as error:
        raise ObjectNotReadyError(f"s3://{bucket}/{key} is not there yet") from error
    value = json.loads(raw)
    return {
        "key": key,
        "size_bytes": len(raw),
        "item_count": len(value) if isinstance(value, dict | list) else 1,
    }


def handler(event: dict[str, str], context: Any, s3: Any = None) -> dict[str, Any]:
    s3 = s3 or boto3.client("s3")
    summary = read_file(s3, event["bucket"], event["key"])
    logger.info("read %s (%d bytes)", summary["key"], summary["size_bytes"])
    return summary
