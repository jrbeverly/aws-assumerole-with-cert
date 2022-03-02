#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

repository_link="$@"
dir_output="${ROOT_DIR}/output/${repository_link}"

aws iot create-thing-type --thing-type-name "${repository_link}"
aws iot create-thing --thing-name "${repository_link}" --thing-type-name "${repository_link}" --attribute-payload "{\"attributes\": {\"Owner\":\"jrbeverly\"}}"


mkdir -p "${dir_output}"
certificate_arn="$(aws iot create-keys-and-certificate \
    --set-as-active \
    --certificate-pem-outfile "${dir_output}/certificate_filename.pem" \
    --public-key-outfile "${dir_output}/public_filename.key" \
    --private-key-outfile "${dir_output}/private_filename.key" |  jq -r '.certificateArn')"

# Attach thing to certificate
aws iot attach-thing-principal --thing-name "${repository_link}" --principal "${certificate_arn}"

# Create an IAM Role
rolearn="$(aws iam create-role --role-name "${repository_link}" --assume-role-policy-document file://${SCRIPT_DIR}/iam/trustpolicyforiot.json | jq -r '.Role.Arn')"

# Now to attach the role alias
rolealias_arn="$(aws iot create-role-alias --role-alias "${repository_link}" --role-arn "${rolearn}" --credential-duration-seconds 3600 | jq -r '.roleAliasArn')"

# Create policy for the certificate
certpolicy="${dir_output}/certpolicy.json"
cat <<EOT > "${certpolicy}"
{
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Action": "iot:AssumeRoleWithCertificate",
      "Resource": "${rolealias_arn}",
      "Condition": {
        "StringEquals": {
          "iot:Connection.Thing.Attributes[Owner]": "jrbeverly",
          "iot:Connection.Thing.ThingTypeName": "${repository_link}"
        },
        "Bool": {
          "iot:Connection.Thing.IsAttached": "true"
        }
      }
    }
  }
EOT
aws iot create-policy --policy-name "${repository_link}" --policy-document "file://${certpolicy}"

# Attach policy to certificate
aws iot attach-policy --policy-name "${repository_link}" --target "${certificate_arn}"

# Get the IoT Endpoint
endpointAddress="$(aws iot describe-endpoint --endpoint-type iot:CredentialProvider | jq -r '.endpointAddress')"

certpolicy="${dir_output}/auth.yaml"
cat <<EOT > "${certpolicy}"
apiVersion: v1
kind: Config
preferences: {}
current-role: "$(aws configure get region)"
roles:
- role:
    certificate: |
$(cat "${dir_output}/certificate_filename.pem" | sed -e 's/^/      /')
    key: |
$(cat "${dir_output}/private_filename.key" | sed -e 's/^/      /')
    payload: 
      thingname: ${repository_link}
    endpoint: https://${endpointAddress}/role-aliases/${repository_link}/credentials
  name: $(aws configure get region)
EOT