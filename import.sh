#!/bin/bash
# 
# Export the QUEUE stream from the system that was imported to Synadia Cloud and then import it into the Synadia Cloud NGS system

set -eu -o pipefail

# require SCP account ID of the account that will import the stream
if [ -z "$1" ]; then
  echo "Error: SCP account public nkey of the account that will import the stream is required"
  exit 1
fi
IMPORT_ACCOUNT_NKEY=$1

# require SCP_SERVER and SCP_TOKEN
if [ -z "$SCP_SERVER" ]; then
  echo "Error: SCP_SERVER environment variable is required"
  exit 1
fi
if [ -z "$SCP_TOKEN" ]; then
  echo "Error: SCP_TOKEN environment variable is required" 
  exit 1
fi

# decode JWT token
# shellcheck disable=SC2120
jwtd() {
  local input
  if [ -t 0 ]
  then
    input="$1" 
  else
    input=$(cat) 
  fi
  echo "$input" | jq -R 'split(".") |.[0:2] | map(gsub("-"; "+") | gsub("_"; "/") | gsub("%3D"; "=") | @base64d) | map(fromjson)'
}

# get public nkey of A account from .nsc
A_NKEY=$(cat .nsc/memory/accounts/A/A.jwt | jwtd | jq -r '.[1].sub')

EXPORT_ID=
export_queue_stream() {
  http --ignore-stdin --check-status --output=./body "$SCP_SERVER/api/core/beta/accounts/$A_NKEY" -A bearer -a "$SCP_TOKEN" --body
  EXPORT_ACCOUNT_ID=$(cat ./body | jq -r '.id')
  rm ./body

  # create private stream export
  http --ignore-stdin --check-status --output=./body POST "$SCP_SERVER/api/core/beta/accounts/$EXPORT_ACCOUNT_ID/stream-exports" -A bearer -a "$SCP_TOKEN" \
    'is_public:=false' \
    'stream_name=QUEUE'
  EXPORT=$(cat ./body)
  EXPORT_ID=$(cat ./body | jq -r '.id')
  rm ./body
  echo "Stream exported: $EXPORT_ID"

  # share the stream export with the import account
  http --ignore-stdin --quiet --check-status POST "$SCP_SERVER/api/core/beta/stream-exports/$EXPORT_ID/shares" -A bearer -a "$SCP_TOKEN" \
    "target_account_nkey_public=$IMPORT_ACCOUNT_NKEY"
  echo "Stream export shared with import account: $IMPORT_ACCOUNT_NKEY"

  # get the import account ID
  http --ignore-stdin --check-status --output=./body "$SCP_SERVER/api/core/beta/accounts/$IMPORT_ACCOUNT_NKEY" -A bearer -a "$SCP_TOKEN" --body
  IMPORT_ACCOUNT_ID=$(cat ./body | jq -r '.id')
  rm ./body
  echo "Import account ID: $IMPORT_ACCOUNT_ID"

  # import the shared stream
  echo "$EXPORT"
  deliver_subject_prefix=$(echo "$EXPORT" | jq -r '.deliver_subject_prefix')
  js_subject_prefix=$(echo "$EXPORT" | jq -r '.js_subject_prefix')

  http --ignore-stdin --quite --check-status --output=./body POST "$SCP_SERVER/api/core/beta/accounts/$IMPORT_ACCOUNT_ID/stream-imports" -A bearer -a "$SCP_TOKEN" \
    "deliver_subject_prefix=$deliver_subject_prefix" \
    "is_public:=false" \
    "js_subject_prefix=$js_subject_prefix" \
    "remote_account_nkey_public=$A_NKEY" \
    "stream_name=QUEUE"
  IMPORT_ID=$(cat ./body | jq -r '.id')
  rm ./body
  echo "Stream imported: $IMPORT_ID"

  # mirror the imported stream
}

# main
export_queue_stream
echo "Stream export created: $EXPORT_ID"
