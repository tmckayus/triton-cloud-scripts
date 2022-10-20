#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: MIT

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

NAMESPACE=triton
kubectl create namespace $NAMESPACE

tokenstring=""
if [ -n "$AWS_SESSION_TOKEN" ]; then
    tokenstring="--set aws_auth.AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
fi

helm install tritonserver tritoninferenceserver --values tritoninferenceserver/values.yaml --set aws_auth.AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" --set aws_auth.AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" $tokenstring --set image.modelRepositoryPath="$MODEL_REPOSITORY" --set aws_auth.AWS_DEFAULT_REGION="$MODEL_REPOSITORY_REGION" --namespace $NAMESPACE
