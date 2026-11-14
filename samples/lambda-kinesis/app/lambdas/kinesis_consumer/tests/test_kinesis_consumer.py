import base64
import json

import boto3
import pytest
from botocore.stub import Stubber

import kinesis_consumer

TABLE = "lab-events"


def record(data: bytes | dict, sequence_number: str) -> dict:
    raw = json.dumps(data).encode() if isinstance(data, dict) else data
    return {"kinesis": {"data": base64.b64encode(raw).decode(), "sequenceNumber": sequence_number}}


def put_params(event_id: str, sequence_number: str, payload: dict) -> dict:
    return {
        "TableName": TABLE,
        "Item": {
            "pk": {"S": event_id},
            "payload": {"S": json.dumps(payload)},
            "sequence_number": {"S": sequence_number},
        },
        "ConditionExpression": "attribute_not_exists(pk)",
    }


def run(records: list[dict], stub_setup) -> dict:
    dynamodb = boto3.client("dynamodb")
    with Stubber(dynamodb) as stub:
        stub_setup(stub)
        result = kinesis_consumer.handler({"Records": records}, None, dynamodb=dynamodb, table_name=TABLE)
        stub.assert_no_pending_responses()
    return result


def test_decode_record():
    assert kinesis_consumer.decode_record(record({"id": "evt-1", "value": 42}, "1")) == {"id": "evt-1", "value": 42}


@pytest.mark.parametrize(
    "data",
    [b"not-json", b"[1, 2]", b'{"value": 1}', b'{"id": ""}', b'{"id": 7}', b"\xff\xfe"],
    ids=["not json", "not an object", "no id", "empty id", "id not a string", "not utf-8"],
)
def test_decode_record_rejects_what_is_not_an_event(data):
    with pytest.raises(ValueError):
        kinesis_consumer.decode_record(record(data, "1"))


def test_decode_record_rejects_invalid_base64():
    with pytest.raises(ValueError):
        kinesis_consumer.decode_record({"kinesis": {"data": "***", "sequenceNumber": "1"}})


def test_valid_batch_stores_every_event():
    def setup(stub):
        stub.add_response("put_item", {}, put_params("a", "1", {"id": "a"}))
        stub.add_response("put_item", {}, put_params("b", "2", {"id": "b"}))

    assert run([record({"id": "a"}, "1"), record({"id": "b"}, "2")], setup) == {"batchItemFailures": []}


def test_mixed_batch_reports_only_the_invalid_record():
    def setup(stub):
        stub.add_response("put_item", {}, put_params("a", "1", {"id": "a"}))
        stub.add_response("put_item", {}, put_params("c", "3", {"id": "c"}))

    result = run([record({"id": "a"}, "1"), record(b"not-json", "2"), record({"id": "c"}, "3")], setup)
    assert result == {"batchItemFailures": [{"itemIdentifier": "2"}]}


def test_duplicate_is_a_success():
    def setup(stub):
        stub.add_client_error("put_item", service_error_code="ConditionalCheckFailedException")

    assert run([record({"id": "a"}, "1")], setup) == {"batchItemFailures": []}


def test_other_dynamodb_error_is_reported():
    def setup(stub):
        stub.add_client_error("put_item", service_error_code="ProvisionedThroughputExceededException")

    assert run([record({"id": "a"}, "1")], setup) == {"batchItemFailures": [{"itemIdentifier": "1"}]}
