#!/bin/bash

set -euo pipefail

SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")
pushd "${SCRIPTS_DIR}/../postgres_test_builds"
bazel build //...
