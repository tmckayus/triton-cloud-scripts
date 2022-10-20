#!/bin/bash
if [ "$AZURE_STORAGE_KEY" == "" ]; then
    read -sp 'Enter an AZURE_STORAGE_KEY: ' AZURE_STORAGE_KEY
fi
echo
export TF_VAR_azure_storage_key=$AZURE_STORAGE_KEY
../build-triton-server.sh
