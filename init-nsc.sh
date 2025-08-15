#!/bin/bash
# shellcheck disable=SC2016

set -eux o pipefail

NSC_DIR=./.nsc

# remove existing nsc directory
rm -rf "$NSC_DIR"

# create nsc directory if it doesn't exist
mkdir -p "$NSC_DIR"

# create operator
nsc --all-dirs "$NSC_DIR" add operator --name local --generate-signing-key --sys

# create default account
nsc --all-dirs "$NSC_DIR" add account --name A
nsc --all-dirs "$NSC_DIR" edit account --name A --js-enable 1
nsc --all-dirs "$NSC_DIR" edit account --name A --js-enable 3

# create users in default account
nsc --all-dirs "$NSC_DIR" add user --name admin --account A
nsc --all-dirs "$NSC_DIR" add user --name orders --account A --allow-sub 'QUEUE.ORDERS.> ORDERS' --allow-pub 'QUEUE.SHIPMENTS.>'
nsc --all-dirs "$NSC_DIR" add user --name shipments --account A --allow-sub 'QUEUE.SHIPMENTS.> SHIPMENTS'

# # export 
# nsc --all-dirs "$NSC_DIR" add export --name JS_API --account A --subject '$JS.API.>'
# nsc --all-dirs "$NSC_DIR" add export --name JS_FC  --account A --subject '$JS.FC.>'
# nsc --all-dirs "$NSC_DIR" add export --name test   --account A --subject 'test'

# A_NKEY=$(nsc --all-dirs "$NSC_DIR" describe account --name A --json | jq -r .sub)

# # import using JS domain "leaf"
# nsc --all-dirs "$NSC_DIR" add import --name JS_API --account leaf --src-account "$A_NKEY" --remote-subject '$JS.API.>' --local-subject '$JS.leaf.API.>'
# nsc --all-dirs "$NSC_DIR" add import --name JS_FC  --account leaf --src-account "$A_NKEY" --remote-subject '$JS.FC.>'  --local-subject '$JS.leaf.FC.>'
# nsc --all-dirs "$NSC_DIR" add import --name test   --account leaf --src-account "$A_NKEY" --remote-subject 'test'      --local-subject 'test.leaf'

# generate server config from nsc
nsc --all-dirs "$NSC_DIR" generate config --mem-resolver --config-file "$NSC_DIR/nsc.conf"
