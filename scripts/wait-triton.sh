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
helm list -n $NAMESPACE
echo Waiting for triton server pod to be created ...
i=0
while true
do
    pods=$(kubectl get -n $NAMESPACE pod --selector app=tritoninferenceserver)
    if [ -n "$pods" ]; then
	break
    fi
    i=$((i+1))
    if [ "$i" -eq 6 ]; then
        echo triton server pod not created in five minutes, exiting
        exit -1
    fi
    sleep 60
done
echo Waiting for triton server pod to be 'Running' ...
kubectl -n $NAMESPACE wait pod --for=jsonpath='{.status.phase}'=Running --selector app=tritoninferenceserver --timeout=1800s
