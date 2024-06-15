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

# Install necessary packages
apt-get update && apt-install-and-clear -y --no-install-recommends git cmake python3-setuptools python3-pip

# Upgrade pip
pip3 install --upgrade pip

# Install Python dependencies (excluding FP16)
pip3 install numpy six

# Clone and build FP16 manually
RETRY_COUNT=3
RETRY_DELAY=5
SUCCESS=false

for ((i=1; i<=RETRY_COUNT; i++)); do
  if git clone https://github.com/Maratyszcza/FP16.git /FP16; then
    SUCCESS=true
    break
  else
    echo "Attempt $i of $RETRY_COUNT to clone FP16 failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  fi
done

if [ "$SUCCESS" = false ]; then
  echo "Failed to clone FP16 repository after $RETRY_COUNT attempts."
  exit 1
fi

# Install FP16 manually
cd /FP16
mkdir build
cd build
cmake ..
make -j $(nproc)
make install

# Clone NNPACK and pthreadpool
cd /
git clone https://github.com/Maratyszcza/NNPACK NNPACK
git clone https://github.com/Maratyszcza/pthreadpool NNPACK/pthreadpool

# Use specific versioning tag
(cd NNPACK && git checkout 70a77f485)
(cd NNPACK/pthreadpool && git checkout 43edadc)

# Build and install NNPACK
mkdir -p NNPACK/build
cd NNPACK/build
cmake -DCMAKE_INSTALL_PREFIX:PATH=. -DNNPACK_INFERENCE_ONLY=OFF -DNNPACK_CONVOLUTION_ONLY=OFF -DNNPACK_BUILD_TESTS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DPTHREADPOOL_SOURCE_DIR=pthreadpool ..
make -j $(nproc)
make install
cd -
