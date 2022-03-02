#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

repository_link="$@"
auth_file="output/${repository_link}/auth.yaml"

extract_dir="${ROOT_DIR}/extract/"
mkdir -p "${extract_dir}"
yq e '.roles[0].role.certificate' "${auth_file}" > "${extract_dir}/certificate.pem.crt"
yq e '.roles[0].role.key' "${auth_file}" > "${extract_dir}/private.pem.crt"
curl -s \
    --cert "${extract_dir}/certificate.pem.crt" \
    --key "${extract_dir}/private.pem.crt" \
    -H "x-amzn-iot-thingname: $(yq e '.roles[0].role.payload.thingname' "${auth_file}")" \
    "$(yq e '.roles[0].role.endpoint' "${auth_file}")" | jq '.'
rm -rf "${extract_dir}"
