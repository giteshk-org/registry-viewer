#!/bin/bash
#
# Copyright 2021 Google LLC. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script uses Docker buildx to build multi-platform images of
# the registry server and related components.
 
# Available platforms will depend on the local installation of Docker.

# ORGANIZATION should be dockerhub organization that will host the images
#ORGANIZATION=

#TARGET=dev

if [[ $TARGET == "dev" ]]
then
  # If TARGET is specified as "dev", container names have the suffix "-dev".
  SUFFIX="-$TARGET"
  CONTAINERS=("registry-viewer")
  PLATFORMS="linux/amd64,linux/arm64"
else
  SUFFIX=""
  CONTAINERS=("registry-viewer")
  PLATFORMS="linux/amd64,linux/arm64"
fi

# This builds each desired container sequentially.
for CONTAINER in ${CONTAINERS[*]}; do
docker buildx build \
	--file containers/${CONTAINER}/Dockerfile \
	--tag ${ORGANIZATION}/${CONTAINER}${SUFFIX}:latest \
	--platform $PLATFORMS \
	--progress plain \
	--push \
	.
done
