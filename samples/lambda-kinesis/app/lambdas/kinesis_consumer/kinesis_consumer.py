"""Consumes the Kinesis records: every valid JSON event is stored once in DynamoDB, the invalid ones are reported."""

import base64
import json
import logging
import os
from typing import Any

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def decode_record(record: dict[str, Any]) -> dict[str, Any]:
    """Event carried by a Kinesis record. Raises ValueError unless it is a JSON object with a non-empty string `id`."""
    raw = base64.b64decode(record["kinesis"]["data"], validate=True)
    event = json.loads(raw)
    if not isinstance(event, dict) or not isinstance(event.get("id"), str) or not event["id"]:
        raise ValueError("the event must be a JSON object with a non-empty string id")
    return event


def store_event(dynamodb: Any, table_name: str, event: dict[str, Any], sequence_number: str) -> None:
    """Stores the event once. A second delivery of the same id (a retry of the batch) is a success, not an error."""
    try:
        dynamodb.put_item(
            TableName=table_name,
            Item={
                "pk": {"S": event["id"]},
                "payload": {"S": json.dumps(event)},
                "sequence_number": {"S": sequence_number},
            },
            ConditionExpression="attribute_not_exists(pk)",
        )
    except ClientError as error:
        if error.response["Error"]["Code"] != "ConditionalCheckFailedException":
            raise


def handler(
    event: dict[str, Any], context: Any, dynamodb: Any = None, table_name: str | None = None
) -> dict[str, list[dict[str, str]]]:
    """Partial batch response: Lambda retries from the first record reported, the others are not lost nor duplicated."""
    dynamodb = dynamodb or boto3.client("dynamodb")
    table_name = table_name or os.environ["TABLE_NAME"]
    failures = []
    for record in event["Records"]:
        sequence_number = record["kinesis"]["sequenceNumber"]
        try:
            store_event(dynamodb, table_name, decode_record(record), sequence_number)
        except (ValueError, ClientError):
            logger.exception("record %s failed", sequence_number)
            failures.append({"itemIdentifier": sequence_number})
    return {"batchItemFailures": failures}
