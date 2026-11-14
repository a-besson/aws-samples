import io
import json

import boto3
import pytest
from botocore.response import StreamingBody
from botocore.stub import Stubber

import s3_reader


def record(key: str, bucket: str = "lab-bucket") -> dict:
    return {"s3": {"bucket": {"name": bucket}, "object": {"key": key}}}


def body(raw: bytes) -> StreamingBody:
    return StreamingBody(io.BytesIO(raw), len(raw))


def test_summarize_object():
    raw = b'{"id": "ok", "items": [1, 2, 3]}'
    assert s3_reader.summarize("incoming/ok.json", raw) == {
        "source_key": "incoming/ok.json",
        "size_bytes": len(raw),
        "top_level_type": "object",
        "item_count": 2,
    }


@pytest.mark.parametrize(
    ("raw", "top_level_type", "item_count"),
    [
        (b"[1, 2, 3]", "array", 3),
        (b'"text"', "string", 1),
        (b"42", "number", 1),
        (b"true", "boolean", 1),
        (b"null", "null", 1),
    ],
)
def test_summarize_other_types(raw, top_level_type, item_count):
    summary = s3_reader.summarize("incoming/x.json", raw)
    assert (summary["top_level_type"], summary["item_count"]) == (top_level_type, item_count)


def test_summarize_invalid_json_raises():
    with pytest.raises(ValueError):
        s3_reader.summarize("incoming/poison.json", b"not-json")


def test_handler_writes_the_summary():
    raw = b'{"id": "ok", "items": [1, 2, 3]}'
    s3 = boto3.client("s3")
    with Stubber(s3) as stub:
        stub.add_response("get_object", {"Body": body(raw)}, {"Bucket": "lab-bucket", "Key": "incoming/ok.json"})
        stub.add_response(
            "put_object",
            {},
            {
                "Bucket": "lab-bucket",
                "Key": "processed/ok.json",
                "Body": json.dumps(s3_reader.summarize("incoming/ok.json", raw)).encode(),
                "ContentType": "application/json",
            },
        )
        assert s3_reader.handler({"Records": [record("incoming/ok.json")]}, None, s3=s3) == {
            "processed": ["processed/ok.json"]
        }
        stub.assert_no_pending_responses()


def test_handler_decodes_the_key_of_the_notification():
    s3 = boto3.client("s3")
    with Stubber(s3) as stub:
        stub.add_response("get_object", {"Body": body(b"{}")}, {"Bucket": "lab-bucket", "Key": "incoming/a b.json"})
        stub.add_response("put_object", {}, None)
        assert s3_reader.handler({"Records": [record("incoming/a+b.json")]}, None, s3=s3) == {
            "processed": ["processed/a b.json"]
        }


def test_handler_raises_on_invalid_json_and_writes_nothing():
    s3 = boto3.client("s3")
    with Stubber(s3) as stub:
        stub.add_response(
            "get_object", {"Body": body(b"not-json")}, {"Bucket": "lab-bucket", "Key": "incoming/poison.json"}
        )
        with pytest.raises(ValueError):
            s3_reader.handler({"Records": [record("incoming/poison.json")]}, None, s3=s3)
        stub.assert_no_pending_responses()  # the only call was the read: no put_object


def test_handler_ignores_a_key_outside_the_prefix():
    s3 = boto3.client("s3")
    with Stubber(s3):  # no response queued: any S3 call would fail
        assert s3_reader.handler({"Records": [record("processed/ok.json")]}, None, s3=s3) == {"processed": []}
