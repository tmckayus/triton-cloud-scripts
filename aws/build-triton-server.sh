#!/bin/bash
if [ "$AWS_ACCESS_KEY_ID" == "" ]; then
    read -sp 'Enter a AWS_ACCESS_KEY_ID: ' AWS_ACCESS_KEY_ID
fi
echo

if [ "$AWS_SECRET_ACCESS_KEY" == "" ]; then
    read -sp 'Enter a AWS_SECRET_ACCESS_KEY: ' AWS_SECRET_ACCESS_KEY
fi
echo

# Session token may not be required depending on the account,
# so we don't force a prompt for it
# However we do fix up the values.yaml file in overrides so
# that it will be set or unset in the manifest ....
if [ -n "$AWS_SESSION_TOKEN" ]; then
    cp overrides/tritoninferenceserver/values-session.yaml overrides/tritoninferenceserver/values.yaml
    export TF_VAR_aws_session_token=$AWS_SESSION_TOKEN
else
    cp overrides/tritoninferenceserver/values-nosession.yaml overrides/tritoninferenceserver/values.yaml
fi

export TF_VAR_aws_access_key_id=$AWS_ACCESS_KEY_ID
export TF_VAR_aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
../build-triton-server.sh
