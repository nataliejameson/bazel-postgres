#!/bin/bash

set -euo pipefail

pushd postgres_test_builds
bazel build //...
