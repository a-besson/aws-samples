#!/usr/bin/env bash
# Runs an aws CLI call against the local Floci emulator only (fake credentials), once or until it returns a value.
# Usage: floci-aws.sh <endpoint> run <aws args...>
#        floci-aws.sh <endpoint> wait <timeout-seconds> <aws args...>
# Prints {"output": "<text>"} for the Terraform `external` data source.
set -euo pipefail

endpoint="$1"
mode="$2"
shift 2
case "$endpoint" in
  http://localhost:* | http://127.0.0.1:*) ;;
  *) echo "refusing non-local endpoint: $endpoint" >&2; exit 2 ;;
esac
export AWS_ENDPOINT_URL="$endpoint" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
unset AWS_PROFILE AWS_SESSION_TOKEN

timeout=0
if [ "$mode" = wait ]; then
  timeout="$1"
  shift
fi
err="$(mktemp)"
trap 'rm -f "$err"' EXIT
deadline=$((SECONDS + timeout))
while :; do
  if out="$(aws "$@" --output text 2>"$err")" && [ -n "$out" ] && [ "$out" != None ]; then
    break
  fi
  if [ "$mode" = run ] || [ "$SECONDS" -ge "$deadline" ]; then
    echo "no result after ${timeout}s: aws $*" >&2
    cat "$err" >&2 # last error of the CLI: tells a sample bug from an emulator gap
    exit 1
  fi
  sleep 2
done
jq -n --arg output "$out" '{output: $output}'
