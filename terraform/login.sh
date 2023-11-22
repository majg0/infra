#!/bin/sh

# NOTE: remember to `source login.sh`, or env vars are scoped to the new process
export AWS_DEFAULT_REGION="$1"
export AWS_DEFAULT_PROFILE="$2"

aws sso login --sso-session "$2"
