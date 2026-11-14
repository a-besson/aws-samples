import io

import boto3
import pytest
from botocore.response import StreamingBody
from botocore.stub import Stubber

import manifest_reader


def body(raw: bytes) -> StreamingBody:
    return StreamingBody(io.BytesIO(raw), len(raw))


def test_reads_the_file():
    raw = b'{"id": "a", "items": [1, 2, 3]}'
    s3 = boto3.client("s3")
    with Stubber(s3) as stub:
        stub.add_response("get_object", {"Body": body(raw)}, {"Bucket": "lab-bucket", "Key": "data/a.json"})
        result = manifest_reader.handler({"bucket": "lab-bucket", "key": "data/a.json"}, None, s3=s3)
    assert result == {"key": "data/a.json", "size_bytes": len(raw), "item_count": 2}


def test_missing_file_is_not_ready():
    s3 = boto3.client("s3")
    with Stubber(s3) as stub:
        stub.add_client_error("get_object", service_error_code="NoSuchKey")
        with pytest.raises(manifest_reader.ObjectNotReadyError):
            manifest_reader.handler({"bucket": "lab-bucket", "key": "data/missing.json"}, None, s3=s3)


def test_invalid_json_is_not_retryable():
    s3 = boto3.client("s3")
    with Stubber(s3) as stub:
        stub.add_response("get_object", {"Body": body(b"not-json")}, {"Bucket": "lab-bucket", "Key": "data/bad.json"})
        with pytest.raises(ValueError):
            manifest_reader.handler({"bucket": "lab-bucket", "key": "data/bad.json"}, None, s3=s3)
    assert not issubclass(ValueError, manifest_reader.ObjectNotReadyError)


def test_other_s3_errors_are_not_masked():
    s3 = boto3.client("s3")
    with Stubber(s3) as stub:
        stub.add_client_error("get_object", service_error_code="AccessDenied")
        with pytest.raises(s3.exceptions.ClientError):
            manifest_reader.handler({"bucket": "lab-bucket", "key": "other/x.json"}, None, s3=s3)
