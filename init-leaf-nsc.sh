#!/bin/bash
# shellcheck disable=SC2016

set -eux o pipefail

NSC_DIR=./.leaf

# remove existing nsc directory
rm -rf "$NSC_DIR"

# create nsc directory if it doesn't exist
mkdir -p "$NSC_DIR"

# create operator
nsc --all-dirs "$NSC_DIR" add operator --name leaf --generate-signing-key --sys

# create default account
nsc --all-dirs "$NSC_DIR" add account --name A
nsc --all-dirs "$NSC_DIR" edit account --name A --js-enable 1
nsc --all-dirs "$NSC_DIR" edit account --name A --js-enable 3

# create user in default account
nsc --all-dirs "$NSC_DIR" add user --name leaf --account A

# generate server config from nsc
nsc --all-dirs "$NSC_DIR" generate config --mem-resolver --config-file "$NSC_DIR/nsc.conf"
