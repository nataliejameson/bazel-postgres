#!/bin/bash

set -euo pipefail

SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")
cd "${SCRIPTS_DIR}/../postgres_test_builds"
bazel test //...
