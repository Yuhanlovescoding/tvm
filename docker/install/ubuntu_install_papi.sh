#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -e
set -u
set -o pipefail

# Update and install necessary packages
apt-get update --fix-missing
apt-install-and-clear -y linux-tools-common linux-tools-generic kmod

# Configure Git to handle network issues better
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global http.followRedirects true

# Retry logic for git clone
RETRY_COUNT=3
RETRY_DELAY=5
SUCCESS=false

for ((i=1; i<=RETRY_COUNT; i++)); do
  if git clone --branch papi-6-0-0-1-t https://github.com/icl-utk-edu/papi /papi; then
    SUCCESS=true
    break
  else
    echo "Attempt $i of $RETRY_COUNT failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  fi
done

if [ "$SUCCESS" = false ]; then
  echo "Failed to clone PAPI repository after $RETRY_COUNT attempts."
  exit 1
fi

# Build and install PAPI
cd /papi/src
export PAPI_CUDA_ROOT=/usr/local/cuda
export PAPI_ROCM_ROOT=/opt/rocm
./configure --with-components="$1"
make -j $(nproc) && make install
