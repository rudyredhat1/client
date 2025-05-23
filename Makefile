#This makefile is used by ci-operator

# Copyright 2019 The OpenShift Knative Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CGO_ENABLED=1
GOOS ?=
GOARCH ?=
TEST_IMAGES=./test/test_images/helloworld knative.dev/serving/test/test_images/grpc-ping knative.dev/serving/test/test_images/multicontainer/servingcontainer knative.dev/serving/test/test_images/multicontainer/sidecarcontainer
TEST=
TEST_IMAGE_TAG ?= latest

install: build
	cp ./kn $(GOPATH)/bin
.PHONY: install

build:
	GOFLAGS='' ./hack/build.sh -f
.PHONY: build

build-with-platform:
	./hack/build.sh -p $(GOOS) $(GOARCH)
.PHONY: build-with-platform

build-cross:
	GOFLAGS='' ./hack/build.sh -x
.PHONY: build-cross

build-cross-package: build-cross
	GOFLAGS='' ./package_cliartifacts.sh
.PHONY: build-cross-package

test-install:
	GOFLAGS='' go install $(TEST_IMAGES)
.PHONY: test-install

test-images:
	for img in $(TEST_IMAGES); do \
		KO_DOCKER_REPO=$(DOCKER_REPO_OVERRIDE) ko build --tags=$(TEST_IMAGE_TAG) $(KO_FLAGS) -B $$img ; \
	done
.PHONY: test-images

test-unit:
	GOFLAGS='' ./hack/build.sh -t
.PHONY: test-unit

test-e2e:
	GOFLAGS='' ./openshift/e2e-tests-openshift.sh
.PHONY: test-e2e

# Run make DOCKER_REPO_OVERRIDE=<your_repo> test-e2e-local if test images are available
# in the given repository. Make sure you first build and push them there by running `make test-images`.
# Run make BRANCH=<ci_promotion_name> test-e2e-local if test images from the latest CI
# build for this branch should be used. Example: `make BRANCH=knative-v0.17.2 test-e2e-local`.
# If neither DOCKER_REPO_OVERRIDE nor BRANCH are defined the tests will use test images
# from the last nightly build.
# If TEST is defined then only the single test will be run.
test-e2e-local:
	./openshift/e2e-tests-local.sh $(TEST)
.PHONY: test-e2e-local

# Generate an aggregated knative release yaml file, as well as a CI file with replaced image references
generate-release:
	./openshift/generate.sh
.PHONY: generate-release
