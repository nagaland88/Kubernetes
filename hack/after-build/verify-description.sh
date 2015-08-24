#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
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

set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE}")/../..
source "${KUBE_ROOT}/hack/lib/init.sh"

kube::golang::setup_env

# Find binary
genswaggertypedocs=$(kube::util::find-binary "genswaggertypedocs")

result=0

find_files() {
  find . -not \( \
      \( \
        -wholename './output' \
        -o -wholename './_output' \
        -o -wholename './release' \
        -o -wholename './target' \
        -o -wholename '*/third_party/*' \
        -o -wholename '*/Godeps/*' \
      \) -prune \
    \) -wholename '*pkg/api/v*/types.go'
}

if [[ $# -eq 0 ]]; then
  versioned_api_files=`find_files | egrep "pkg/api/v.[^/]*/types\.go"`
else
  versioned_api_files=("${@}")
fi

for file in $versioned_api_files; do
  $genswaggertypedocs -v -s "${file}" -f - || result=$?
  if [[ "${result}" -ne "0" ]]; then
    echo "API file: ${file} is missing: ${result} descriptions"
  fi
  if grep json: "${file}" | grep -v // | grep description: ; then
    echo "API file: ${file} should not contain descriptions in struct tags"
    result=1
  fi
done

internal_types_file="${KUBE_ROOT}/pkg/api/types.go"
if grep json: "${internal_types_file}" | grep -v // | grep description: ; then
  echo "Internal API types should not contain descriptions"
  result=1
fi

exit ${result}