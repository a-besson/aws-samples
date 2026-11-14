"""Offline guard of the Python tests of every sample: fake credentials and an AWS endpoint nobody listens on."""

import os

os.environ["AWS_DEFAULT_REGION"] = "eu-west-3"
os.environ["AWS_ACCESS_KEY_ID"] = "test"
os.environ["AWS_SECRET_ACCESS_KEY"] = "test"
os.environ["AWS_ENDPOINT_URL"] = "http://127.0.0.1:9"  # discard port: a call that escapes a stub fails at once
os.environ.pop("AWS_PROFILE", None)
os.environ.pop("AWS_SESSION_TOKEN", None)
